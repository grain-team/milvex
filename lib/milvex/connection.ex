defmodule Milvex.Connection do
  @moduledoc """
  State machine managing gRPC channel lifecycle with automatic reconnection.

  Each connection maintains a gRPC channel to a Milvus server and monitors
  the underlying connection process for failures.

  ## States

  - `:connecting` - Attempting to establish initial connection
  - `:connected` - Channel active, connection monitored
  - `:reconnecting` - Lost connection, attempting to restore

  ## Usage

      # Start a connection
      {:ok, conn} = Milvex.Connection.start_link(host: "localhost", port: 19530)

      # Get the gRPC channel for making calls
      {:ok, channel} = Milvex.Connection.get_channel(conn)

      # Disconnect
      :ok = Milvex.Connection.disconnect(conn)

  ## Named Connections

      # Start a named connection
      {:ok, _} = Milvex.Connection.start_link([host: "localhost"], name: :milvus)

      # Use the named connection
      {:ok, channel} = Milvex.Connection.get_channel(:milvus)

  ## Reconnection Behavior

  The connection monitors the underlying gRPC connection process. When the
  connection dies, it automatically reconnects using exponential backoff
  with jitter to prevent thundering herd problems.

  Configuration options:
  - `:reconnect_base_delay` - Base delay in ms (default: 1000)
  - `:reconnect_max_delay` - Maximum delay cap in ms (default: 60000)
  - `:reconnect_multiplier` - Exponential multiplier (default: 2.0)
  - `:reconnect_jitter` - Jitter factor 0.0-1.0 (default: 0.1)
  """

  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  require Logger

  alias Milvex.Backoff
  alias Milvex.Config
  alias Milvex.Errors

  defstruct [:config, :channel, :conn_monitor_ref, retry_count: 0]

  @type t :: %__MODULE__{
          config: Config.t(),
          channel: GRPC.Channel.t() | nil,
          conn_monitor_ref: reference() | nil,
          retry_count: non_neg_integer()
        }

  @type state :: :connecting | :connected | :reconnecting

  @doc """
  Starts a connection to a Milvus server.

  ## Options

  - `:name` - Optional name to register the connection process
  - All other options are passed to `Milvex.Config.parse/1`

  ## Examples

      {:ok, conn} = Milvex.Connection.start_link(host: "localhost", port: 19530)
      {:ok, conn} = Milvex.Connection.start_link([host: "localhost"], name: :milvus)
  """
  @spec start_link(keyword()) :: GenStateMachine.on_start()
  def start_link(opts) do
    {name, config_opts} = Keyword.pop(opts, :name)

    gen_opts = if name, do: [name: name], else: []
    GenStateMachine.start_link(__MODULE__, config_opts, gen_opts)
  end

  @doc """
  Gets the gRPC channel and call options from the connection.

  Returns `{:ok, channel, call_opts}` if connected, or `{:error, error}` if not connected.
  The `call_opts` keyword list contains options to pass to gRPC calls, including `:timeout`.
  """
  @spec get_channel(GenServer.server(), keyword()) ::
          {:ok, GRPC.Channel.t()} | {:error, Milvex.Error.t()}
  def get_channel(conn, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5_000)
    GenStateMachine.call(conn, :get_channel, timeout)
  end

  @doc """
  Disconnects from the Milvus server and stops the connection process.
  """
  @spec disconnect(GenServer.server()) :: :ok
  def disconnect(conn) do
    GenStateMachine.stop(conn, :normal)
  end

  @doc """
  Checks if the connection is currently established.
  """
  @spec connected?(GenServer.server(), keyword()) :: boolean()
  def connected?(conn, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5_000)
    GenStateMachine.call(conn, :connected?, timeout)
  end

  @impl true
  def init(config_opts) do
    case Config.parse(config_opts) do
      {:ok, config} ->
        data = %__MODULE__{
          config: config,
          channel: nil,
          conn_monitor_ref: nil,
          retry_count: 0
        }

        {:ok, :connecting, data}

      {:error, error} ->
        {:stop, error}
    end
  end

  # --- :connecting state ---

  def connecting(:enter, _old_state, _data) do
    {:keep_state_and_data, [{:state_timeout, 0, :connect}]}
  end

  def connecting(:state_timeout, :connect, data) do
    case establish_connection(data.config) do
      {:ok, channel, monitor_ref} ->
        {:next_state, :connected,
         %{data | channel: channel, conn_monitor_ref: monitor_ref, retry_count: 0}}

      {:error, reason} ->
        delay = calculate_backoff_delay(data)

        Logger.warning(
          "Failed to connect to Milvus: #{inspect(reason)}, retrying in #{delay}ms..."
        )

        {:keep_state, %{data | retry_count: data.retry_count + 1},
         [{:state_timeout, delay, :retry}]}
    end
  end

  def connecting(:state_timeout, :retry, data) do
    case establish_connection(data.config) do
      {:ok, channel, monitor_ref} ->
        {:next_state, :connected,
         %{data | channel: channel, conn_monitor_ref: monitor_ref, retry_count: 0}}

      {:error, reason} ->
        delay = calculate_backoff_delay(data)
        Logger.warning("Connection retry failed: #{inspect(reason)}, retrying in #{delay}ms...")

        {:keep_state, %{data | retry_count: data.retry_count + 1},
         [{:state_timeout, delay, :retry}]}
    end
  end

  def connecting({:call, from}, :get_channel, data) do
    {:keep_state_and_data, [{:reply, from, not_connected_error(data)}]}
  end

  def connecting({:call, from}, :connected?, _data) do
    {:keep_state_and_data, [{:reply, from, false}]}
  end

  def connecting(:info, _msg, _data) do
    :keep_state_and_data
  end

  # --- :connected state ---

  def connected(:enter, _old_state, _data) do
    :keep_state_and_data
  end

  def connected({:call, from}, :get_channel, data) do
    {:keep_state_and_data, [{:reply, from, {:ok, data.channel}}]}
  end

  def connected({:call, from}, :connected?, _data) do
    {:keep_state_and_data, [{:reply, from, true}]}
  end

  def connected(:info, {:DOWN, ref, :process, _pid, _reason}, %{conn_monitor_ref: ref} = data) do
    {:next_state, :reconnecting, %{data | channel: nil, conn_monitor_ref: nil, retry_count: 0}}
  end

  def connected(:info, {:elixir_grpc, :connection_down, _pid}, data) do
    demonitor_connection(data.conn_monitor_ref)
    close_channel(data.channel)
    {:next_state, :reconnecting, %{data | channel: nil, conn_monitor_ref: nil, retry_count: 0}}
  end

  def connected(:info, {:gun_down, _pid, _protocol, _jreason, _killed_streams}, data) do
    demonitor_connection(data.conn_monitor_ref)
    close_channel(data.channel)
    {:next_state, :reconnecting, %{data | channel: nil, conn_monitor_ref: nil, retry_count: 0}}
  end

  def connected(:info, _msg, _data) do
    :keep_state_and_data
  end

  # --- :reconnecting state ---

  def reconnecting(:enter, _old_state, _data) do
    {:keep_state_and_data, [{:state_timeout, 0, :reconnect}]}
  end

  def reconnecting(:state_timeout, :reconnect, data), do: reconnect(data)

  def reconnecting(:state_timeout, :retry, data), do: reconnect(data)

  def reconnecting({:call, from}, :get_channel, data) do
    {:keep_state_and_data, [{:reply, from, not_connected_error(data)}]}
  end

  def reconnecting({:call, from}, :connected?, _data) do
    {:keep_state_and_data, [{:reply, from, false}]}
  end

  def reconnecting(:info, _msg, _data) do
    :keep_state_and_data
  end

  # --- Termination ---

  @impl true
  def terminate(_reason, _state, data) do
    if data.channel do
      close_channel(data.channel)
    end

    demonitor_connection(data.conn_monitor_ref)

    :ok
  end

  # --- Private helpers ---

  defp reconnect(data) do
    case establish_connection(data.config) do
      {:ok, channel, monitor_ref} ->
        {:next_state, :connected,
         %{data | channel: channel, conn_monitor_ref: monitor_ref, retry_count: 0}}

      {:error, reason} ->
        delay = calculate_backoff_delay(data)
        Logger.warning("Reconnection failed: #{inspect(reason)}, retrying in #{delay}ms...")

        {:keep_state, %{data | retry_count: data.retry_count + 1},
         [{:state_timeout, delay, :retry}]}
    end
  end

  defp calculate_backoff_delay(data) do
    Backoff.calculate(
      data.retry_count,
      data.config.reconnect_base_delay,
      data.config.reconnect_max_delay,
      data.config.reconnect_multiplier,
      data.config.reconnect_jitter
    )
  end

  defp not_connected_error(data) do
    {:error,
     Errors.Connection.exception(
       reason: :not_connected,
       host: data.config.host,
       port: data.config.port,
       retriable: true
     )}
  end

  defp establish_connection(config) do
    address = "#{config.host}:#{config.port}"
    opts = build_connection_opts(config)

    Logger.info("Establishing connection to Milvus at #{address}...")

    case GRPC.Stub.connect(address, opts) do
      {:ok, channel} ->
        monitor_ref = monitor_connection(channel)
        {:ok, channel, monitor_ref}

      {:error, reason} ->
        {:error,
         Errors.Connection.exception(
           reason: reason,
           host: config.host,
           port: config.port,
           retriable: true
         )}
    end
  end

  defp monitor_connection(%{adapter_payload: %{conn_pid: conn_pid}}) when is_pid(conn_pid) do
    Process.monitor(conn_pid)
  end

  defp monitor_connection(_channel), do: nil

  defp demonitor_connection(nil), do: :ok

  defp demonitor_connection(ref) do
    Process.demonitor(ref, [:flush])
  end

  defp build_connection_opts(config) do
    []
    |> maybe_add_ssl(config)
    |> maybe_add_auth_headers(config)
    |> maybe_add_adapter(config)
    |> maybe_add_adapter_opts(config)
  end

  defp maybe_add_ssl(opts, %{ssl: true, ssl_options: ssl_options}) do
    cred = GRPC.Credential.new(ssl: ssl_options)
    Keyword.put(opts, :cred, cred)
  end

  defp maybe_add_ssl(opts, _config), do: opts

  defp maybe_add_auth_headers(opts, config) do
    headers = Keyword.get(opts, :headers, [])

    headers =
      case Map.get(config, :token) do
        nil -> headers
        token -> [{"authorization", Base.encode64(token)} | headers]
      end

    headers =
      case Map.get(config, :database) do
        nil -> headers
        "default" -> headers
        db -> [{"dbname", db} | headers]
      end

    if headers == [] do
      opts
    else
      Keyword.put(opts, :headers, headers)
    end
  end

  defp maybe_add_adapter(opts, %{adapter: adapter}) when not is_nil(adapter) do
    Keyword.put(opts, :adapter, adapter)
  end

  defp maybe_add_adapter(opts, _config), do: opts

  defp maybe_add_adapter_opts(opts, %{adapter: GRPC.Client.Adapters.Gun} = config) do
    adapter_opts = Map.get(config, :adapter_opts, [])
    adapter_opts = Keyword.put_new(adapter_opts, :retry, 0)
    Keyword.put(opts, :adapter_opts, adapter_opts)
  end

  defp maybe_add_adapter_opts(opts, %{adapter_opts: adapter_opts}) when adapter_opts != [] do
    Keyword.put(opts, :adapter_opts, adapter_opts)
  end

  defp maybe_add_adapter_opts(opts, _config), do: opts

  defp close_channel(%{adapter_payload: %{conn_pid: conn_pid}} = channel)
       when is_pid(conn_pid) do
    if Process.alive?(conn_pid) do
      GRPC.Stub.disconnect(channel)
    else
      {:ok, channel}
    end
  catch
    :exit, _ -> {:ok, channel}
    :error, _ -> {:ok, channel}
  end

  defp close_channel(channel), do: {:ok, channel}
end

defimpl Inspect, for: Milvex.Connection do
  import Inspect.Algebra

  @redacted_keys [:token, :user, :password]
  @redacted_headers ["authorization"]

  def inspect(%Milvex.Connection{} = conn, opts) do
    redacted = %{
      conn
      | config: redact_config(conn.config),
        channel: redact_channel(conn.channel)
    }

    concat(["#Milvex.Connection<", to_doc(Map.from_struct(redacted), opts), ">"])
  end

  defp redact_config(nil), do: nil

  defp redact_config(config) when is_map(config) do
    Map.new(config, fn
      {key, _value} when key in @redacted_keys -> {key, "[REDACTED]"}
      {key, value} -> {key, value}
    end)
  end

  defp redact_channel(nil), do: nil

  defp redact_channel(%GRPC.Channel{} = channel) do
    %{channel | headers: redact_headers(channel.headers)}
  end

  defp redact_headers(headers) when is_list(headers) do
    Enum.map(headers, fn
      {key, _value} when key in @redacted_headers -> {key, "[REDACTED]"}
      header -> header
    end)
  end

  defp redact_headers(headers), do: headers
end

defimpl Inspect, for: GRPC.Channel do
  import Inspect.Algebra

  @redacted_headers ["authorization"]

  def inspect(%GRPC.Channel{} = channel, opts) do
    redacted = %{channel | headers: redact_headers(channel.headers)}
    concat(["#GRPC.Channel<", to_doc(Map.from_struct(redacted), opts), ">"])
  end

  defp redact_headers(headers) when is_list(headers) do
    Enum.map(headers, fn
      {key, _value} when key in @redacted_headers -> {key, "[REDACTED]"}
      header -> header
    end)
  end

  defp redact_headers(headers), do: headers
end
