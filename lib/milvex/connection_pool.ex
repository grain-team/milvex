defmodule Milvex.ConnectionPool do
  @moduledoc """
  Round-robin pool of `Milvex.Connection` processes.

  Each pooled connection maintains its own gRPC channel, i.e. its own HTTP/2
  connection. HTTP/2 servers cap the number of concurrent streams per
  connection (`SETTINGS_MAX_CONCURRENT_STREAMS`), and strict clients such as
  the Mint adapter reject requests over that limit with
  `:too_many_concurrent_requests`. Pooling multiplies the effective
  concurrent-stream budget by the pool size.

  The pool answers the same call protocol as `Milvex.Connection`, so a pool
  pid or registered name can be used anywhere a connection is expected:

      {:ok, pool} = Milvex.ConnectionPool.start_link(host: "localhost", pool_size: 4)
      {:ok, channel, config} = Milvex.Connection.get_channel(pool)
      {:ok, results} = Milvex.search(pool, "movies", vectors, vector_field: "embedding")

  The usual entry point is `Milvex.Connection.start_link/1` with a
  `:pool_size` option greater than 1, which delegates here.

  ## Behavior

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

  defstruct [:supervisor, :config, next: 0]

  @type t :: %__MODULE__{
          supervisor: pid() | nil,
          config: Config.t(),
          next: non_neg_integer()
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

  Returns `{:ok, channel, config}` if any pooled connection is connected,
  or `{:error, error}` otherwise.
  """
  @spec get_channel(GenServer.server(), keyword()) ::
          {:ok, GRPC.Channel.t(), Config.t()} | {:error, Milvex.Error.t()}
  def get_channel(pool, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5_000)
    GenServer.call(pool, :get_channel, timeout)
  end

  @doc """
  Checks if at least one pooled connection is established.
  """
  @spec connected?(GenServer.server(), keyword()) :: boolean()
  def connected?(pool, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5_000)
    GenServer.call(pool, :connected?, timeout)
  end

  @doc """
  Disconnects all pooled connections and stops the pool.
  """
  @spec disconnect(GenServer.server()) :: :ok
  def disconnect(pool) do
    GenServer.stop(pool, :normal)
  end

  @impl true
  def init(config_opts) do
    case Config.parse(config_opts) do
      {:ok, config} ->
        Process.flag(:trap_exit, true)

        children =
          for index <- 1..config.pool_size do
            %{
              id: {Connection, index},
              start: {Connection, :start_worker, [config_opts]},
              type: :worker
            }
          end

        case Supervisor.start_link(children, strategy: :one_for_one) do
          {:ok, supervisor} ->
            {:ok, %__MODULE__{supervisor: supervisor, config: config}}

          {:error, reason} ->
            {:stop, reason}
        end

      {:error, error} ->
        {:stop, error}
    end
  end

  @impl true
  def handle_call(:get_channel, _from, data) do
    case workers(data) do
      [] ->
        {:reply, not_connected_error(data), data}

      workers ->
        {:reply, pick_channel(workers, data), %{data | next: data.next + 1}}
    end
  end

  def handle_call(:connected?, _from, data) do
    connected? =
      data
      |> workers()
      |> Enum.any?(fn worker ->
        try do
          Connection.connected?(worker)
        catch
          :exit, _ -> false
        end
      end)

    {:reply, connected?, data}
  end

  @impl true
  def handle_info({:EXIT, supervisor, reason}, %{supervisor: supervisor} = data) do
    {:stop, reason, %{data | supervisor: nil}}
  end

  def handle_info(_msg, data) do
    {:noreply, data}
  end

  @impl true
  def terminate(_reason, %{supervisor: supervisor}) when is_pid(supervisor) do
    if Process.alive?(supervisor) do
      Supervisor.stop(supervisor)
    end

    :ok
  catch
    :exit, _ -> :ok
  end

  def terminate(_reason, _data), do: :ok

  defp workers(data) do
    data.supervisor
    |> Supervisor.which_children()
    |> Enum.sort_by(fn {id, _pid, _type, _modules} -> id end)
    |> Enum.flat_map(fn
      {_id, pid, _type, _modules} when is_pid(pid) -> [pid]
      _child -> []
    end)
  end

  defp pick_channel(workers, data) do
    {front, back} = Enum.split(workers, rem(data.next, length(workers)))

    Enum.find_value(back ++ front, not_connected_error(data), fn worker ->
      case fetch_channel(worker) do
        {:ok, _channel, _config} = ok -> ok
        {:error, _error} -> nil
      end
    end)
  end

  defp fetch_channel(worker) do
    Connection.get_channel(worker)
  catch
    :exit, _ -> {:error, :worker_down}
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
end
