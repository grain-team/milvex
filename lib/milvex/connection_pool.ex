defmodule Milvex.ConnectionPool do
  @moduledoc """
  Round-robin pool of `Milvex.Connection` processes.

  Each pooled connection maintains its own gRPC channel, i.e. its own HTTP/2
  connection. HTTP/2 servers cap the number of concurrent streams per
  connection (`SETTINGS_MAX_CONCURRENT_STREAMS`), and strict clients such as
  the Mint adapter reject requests over that limit with
  `:too_many_concurrent_requests`. Pooling multiplies the effective
  concurrent-stream budget by the pool size.

  A pool pid or registered name can be used anywhere a connection is
  expected:

      {:ok, pool} = Milvex.ConnectionPool.start_link(host: "localhost", pool_size: 4)
      {:ok, channel, config} = Milvex.Connection.get_channel(pool)
      {:ok, results} = Milvex.search(pool, "movies", vectors, vector_field: "embedding")

  The usual entry point is `Milvex.Connection.start_link/1` with a
  `:pool_size` option greater than 1, which delegates here.

  ## Behavior

  Channel lookup never goes through the pool process. Each pooled connection
  publishes its channel to a shared ETS table when it connects and removes it
  when it disconnects. Callers pick a channel round-robin in their own
  process using an `:atomics` counter, so `get_channel/2` is lock-free and
  the pool process is never a bottleneck.

  - `get_channel/2` picks connections round-robin. If the picked connection
    is not currently connected, the remaining connections are tried before
    returning a retriable `:not_connected` error.
  - Each connection reconnects independently with the backoff configured via
    `Milvex.Config`.
  - `connected?/2` returns `true` if at least one pooled connection is
    connected.
  - `disconnect/1` stops the pool and all pooled connections.
  """

  use GenServer

  alias Milvex.Config
  alias Milvex.Connection
  alias Milvex.Errors

  defstruct [:supervisor, :entry]

  @typedoc "Lock-free pool entry published via `:persistent_term`."
  @type entry :: %{
          table: :ets.tid(),
          counter: :atomics.atomics_ref(),
          size: pos_integer(),
          config: Config.t()
        }

  @type t :: %__MODULE__{
          supervisor: pid() | nil,
          entry: entry()
        }

  @doc """
  Starts a pool of connections to a Milvus server.

  ## Options

  - `:name` - Optional name to register the pool process
  - `:pool_size` - Number of connections to start (default: 1)
  - All other options are passed to `Milvex.Config.parse/1`
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, config_opts} = Keyword.pop(opts, :name)

    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, config_opts, gen_opts)
  end

  @doc """
  Gets a gRPC channel from the pool, round-robin.

  Lock-free: reads the pool's shared channel table directly from the caller
  process without going through the pool process.

  Returns `{:ok, channel, config}` if any pooled connection is connected,
  or `{:error, error}` otherwise. Exits with `:noproc` if the pool is not
  running.
  """
  @spec get_channel(GenServer.server(), keyword()) ::
          {:ok, Connection.channel(), Config.t()} | {:error, Milvex.Error.t()}
  def get_channel(pool, _opts \\ []) do
    case lookup(pool) do
      {:ok, entry} -> pick_channel(entry)
      :error -> exit({:noproc, {__MODULE__, :get_channel, [pool]}})
    end
  end

  @doc """
  Checks if at least one pooled connection is established.
  """
  @spec connected?(GenServer.server(), keyword()) :: boolean()
  def connected?(pool, _opts \\ []) do
    case lookup(pool) do
      {:ok, entry} -> any_connected?(entry)
      :error -> false
    end
  end

  @doc """
  Disconnects all pooled connections and stops the pool.
  """
  @spec disconnect(GenServer.server()) :: :ok
  def disconnect(pool) do
    GenServer.stop(pool, :normal)
  end

  @doc false
  @spec lookup(GenServer.server()) :: {:ok, entry()} | :error
  def lookup(pool) do
    with pid when is_pid(pid) <- GenServer.whereis(pool),
         %{} = entry <- :persistent_term.get({__MODULE__, pid}, nil) do
      {:ok, entry}
    else
      _ -> :error
    end
  end

  @doc false
  @spec pick_channel(entry()) ::
          {:ok, Connection.channel(), Config.t()} | {:error, Milvex.Error.t()}
  def pick_channel(%{table: table, counter: counter, size: size, config: config}) do
    start = :atomics.add_get(counter, 1, 1)

    Enum.find_value(0..(size - 1), not_connected_error(config), fn offset ->
      index = rem(start + offset, size) + 1
      live_channel(table, index, config)
    end)
  rescue
    ArgumentError -> not_connected_error(config)
  end

  defp live_channel(table, index, config) do
    case :ets.lookup(table, index) do
      [{^index, worker, channel}] ->
        if Process.alive?(worker), do: {:ok, channel, config}

      [] ->
        nil
    end
  end

  @doc false
  @spec any_connected?(entry()) :: boolean()
  def any_connected?(%{table: table}) do
    table
    |> :ets.tab2list()
    |> Enum.any?(fn {_index, worker, _channel} -> Process.alive?(worker) end)
  rescue
    ArgumentError -> false
  end

  @impl true
  def init(config_opts) do
    case Config.parse(config_opts) do
      {:ok, config} ->
        Process.flag(:trap_exit, true)

        table = :ets.new(__MODULE__, [:set, :public, read_concurrency: true])
        counter = :atomics.new(1, [])
        entry = %{table: table, counter: counter, size: config.pool_size, config: config}

        children =
          for index <- 1..config.pool_size do
            worker_opts = Keyword.put(config_opts, :registry, {table, index})

            %{
              id: {Connection, index},
              start: {Connection, :start_worker, [worker_opts]},
              type: :worker
            }
          end

        case Supervisor.start_link(children, strategy: :one_for_one) do
          {:ok, supervisor} ->
            :persistent_term.put({__MODULE__, self()}, entry)
            {:ok, %__MODULE__{supervisor: supervisor, entry: entry}}

          {:error, reason} ->
            {:stop, reason}
        end

      {:error, error} ->
        {:stop, error}
    end
  end

  # Kept for compatibility with callers using the raw call protocol.
  @impl true
  def handle_call(:get_channel, _from, data) do
    {:reply, pick_channel(data.entry), data}
  end

  def handle_call(:connected?, _from, data) do
    {:reply, any_connected?(data.entry), data}
  end

  @impl true
  def handle_info({:EXIT, supervisor, reason}, %{supervisor: supervisor} = data) do
    {:stop, reason, %{data | supervisor: nil}}
  end

  def handle_info(_msg, data) do
    {:noreply, data}
  end

  @impl true
  def terminate(_reason, data) do
    :persistent_term.erase({__MODULE__, self()})

    with %{supervisor: supervisor} when is_pid(supervisor) <- data do
      if Process.alive?(supervisor) do
        Supervisor.stop(supervisor)
      end
    end

    :ok
  catch
    :exit, _ -> :ok
  end

  defp not_connected_error(config) do
    {:error,
     Errors.Connection.exception(
       reason: :not_connected,
       host: config.host,
       port: config.port,
       retriable: true
     )}
  end
end
