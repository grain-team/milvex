defmodule Milvex.Telemetry do
  @moduledoc """
  Telemetry events emitted by Milvex.

  Milvex uses `:telemetry` to emit events for gRPC operations, connection
  lifecycle, and data encoding. You can attach handlers to these events
  using `:telemetry.attach/4` or `:telemetry.attach_many/4`.

  ## RPC Events

  Emitted via `:telemetry.span/3` for every gRPC call through `Milvex.RPC`.

  ### `[:milvex, :rpc, :start]`

  Emitted when a gRPC call begins.

    * Measurements: `%{system_time: integer()}`
    * Metadata:
      * `:method` - The RPC method atom (e.g., `:insert`, `:search`)
      * `:stub` - The gRPC stub module
      * `:collection` - The collection name (or `nil` if not applicable)

  ### `[:milvex, :rpc, :stop]`

  Emitted when a gRPC call completes successfully.

    * Measurements: `%{duration: integer()}` (in native time units)
    * Metadata: same as `:start` plus:
      * `:status_code` - The Milvus status code from the response (or `nil`)

  ### `[:milvex, :rpc, :exception]`

  Emitted when a gRPC call raises an exception.

    * Measurements: `%{duration: integer()}` (in native time units)
    * Metadata: same as `:start` plus:
      * `:kind` - The exception kind (`:error`, `:exit`, `:throw`)
      * `:reason` - The exception reason
      * `:stacktrace` - The stacktrace

  ## Connection Lifecycle Events

  Emitted via `:telemetry.execute/3` from `Milvex.Connection`.

  ### `[:milvex, :connection, :connect]`

  Emitted when a connection is successfully established.

    * Measurements: `%{}`
    * Metadata:
      * `:host` - The Milvus host
      * `:port` - The Milvus port

  ### `[:milvex, :connection, :disconnect]`

  Emitted when a connection is lost.

    * Measurements: `%{}`
    * Metadata:
      * `:host` - The Milvus host
      * `:port` - The Milvus port
      * `:reason` - The disconnect reason

  ### `[:milvex, :connection, :reconnect]`

  Emitted when a reconnection attempt starts.

    * Measurements: `%{}`
    * Metadata:
      * `:host` - The Milvus host
      * `:port` - The Milvus port
      * `:retry_count` - Number of retries so far
      * `:delay_ms` - Backoff delay before this attempt

  ## Data Encoding Events

  Emitted via `:telemetry.span/3` from `Milvex.Data`.

  ### `[:milvex, :data, :encode, :start]`

  Emitted when data encoding (row-to-column conversion) begins.

    * Measurements: `%{system_time: integer()}`
    * Metadata:
      * `:row_count` - Number of rows being encoded
      * `:field_count` - Number of fields in the schema

  ### `[:milvex, :data, :encode, :stop]`

  Emitted when data encoding completes.

    * Measurements: `%{duration: integer()}` (in native time units)
    * Metadata: same as `:start`

  ### `[:milvex, :data, :encode, :exception]`

  Emitted when data encoding raises an exception.

    * Measurements: `%{duration: integer()}` (in native time units)
    * Metadata: same as `:start` plus:
      * `:kind` - The exception kind
      * `:reason` - The exception reason
      * `:stacktrace` - The stacktrace

  ## Example

      :telemetry.attach_many(
        "milvex-logger",
        [
          [:milvex, :rpc, :stop],
          [:milvex, :connection, :connect],
          [:milvex, :connection, :disconnect]
        ],
        fn event, measurements, metadata, _config ->
          Logger.info("Milvex event: \#{inspect(event)}, " <>
            "measurements: \#{inspect(measurements)}, " <>
            "metadata: \#{inspect(metadata)}")
        end,
        nil
      )
  """

  @doc false
  def rpc_metadata(method, stub_module, request) do
    %{
      method: method,
      stub: stub_module,
      collection: extract_collection(request)
    }
  end

  @doc false
  def rpc_span(metadata, fun) do
    :telemetry.span([:milvex, :rpc], metadata, fun)
  end

  @doc false
  def connection_connect(host, port) do
    :telemetry.execute([:milvex, :connection, :connect], %{}, %{
      host: host,
      port: port
    })
  end

  @doc false
  def connection_disconnect(host, port, reason) do
    :telemetry.execute([:milvex, :connection, :disconnect], %{}, %{
      host: host,
      port: port,
      reason: reason
    })
  end

  @doc false
  def connection_reconnect(host, port, retry_count, delay_ms) do
    :telemetry.execute([:milvex, :connection, :reconnect], %{}, %{
      host: host,
      port: port,
      retry_count: retry_count,
      delay_ms: delay_ms
    })
  end

  @doc false
  def data_encode_span(metadata, fun) do
    :telemetry.span([:milvex, :data, :encode], metadata, fun)
  end

  defp extract_collection(request) when is_struct(request) do
    Map.get(request, :collection_name, nil)
  end

  defp extract_collection(_request), do: nil
end
