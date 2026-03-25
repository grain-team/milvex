defmodule Milvex.RPC do
  @moduledoc """
  Low-level gRPC wrapper with consistent error handling.

  Provides helper functions for making gRPC calls and converting
  Milvus proto Status codes and gRPC errors to Splode errors.

  ## Usage

      alias Milvex.RPC
      alias Milvex.Milvus.Proto.Milvus.MilvusService

      # Make a gRPC call with automatic error conversion
      case RPC.call(channel, MilvusService.Stub, :show_collections, request) do
        {:ok, response} -> handle_response(response)
        {:error, error} -> handle_error(error)
      end

      # Check and convert a Milvus Status
      case RPC.check_status(status, "CreateCollection") do
        :ok -> :ok
        {:error, error} -> {:error, error}
      end
  """

  alias Milvex.Error
  alias Milvex.Errors.Connection
  alias Milvex.Errors.Grpc
  alias Milvex.Milvus.Proto.Common.Status
  alias Milvex.Retry
  alias Milvex.Telemetry

  @type rpc_result :: {:ok, struct()} | {:error, Error.t()}

  @doc """
  Call a gRPC method with automatic error conversion.

  The channel function is called on each retry attempt to obtain a fresh
  channel, allowing recovery from dead connections.

  ## Parameters

  - `channel_fn` - `(-> {:ok, GRPC.Channel.t(), Config.t()} | {:error, term()})`
  - `stub_module` - The generated gRPC stub module (e.g., `MilvusService.Stub`)
  - `method` - The RPC method name as an atom (e.g., `:show_collections`)
  - `request` - The request struct
  - `opts` - Options to pass to the gRPC call (e.g., `[timeout: 10_000]`)

  ## Returns

  - `{:ok, response}` on success
  - `{:error, error}` on failure (Connection or Grpc error)

  ## Examples

      RPC.call(
        fn -> Connection.get_channel(conn) end,
        MilvusService.Stub,
        :search,
        request,
        timeout: 30_000
      )
  """
  @retry_keys [:retry_max_attempts, :retry_base_delay, :retry_max_delay, :retry_timeout]
  @grpc_keys [:timeout, :metadata, :content_type, :compressor]

  @spec call(
          (-> {:ok, GRPC.Channel.t(), map()} | {:error, term()}),
          module(),
          atom(),
          struct(),
          keyword()
        ) :: rpc_result()
  def call(channel_fn, stub_module, method, request, opts \\ [])
      when is_function(channel_fn, 0) do
    retry_opts = Keyword.take(opts, @retry_keys)
    grpc_opts = Keyword.take(opts, @grpc_keys)
    telemetry_metadata = Telemetry.rpc_metadata(method, stub_module, request)

    Retry.with_retry(
      fn ->
        with {:ok, channel, _config} <- channel_fn.() do
          do_call(channel, stub_module, method, request, grpc_opts, telemetry_metadata)
        end
      end,
      retry_opts,
      telemetry_metadata
    )
  end

  defp do_call(channel, stub_module, method, request, opts, metadata) do
    Telemetry.rpc_span(metadata, fn ->
      case apply(stub_module, method, [channel, request, opts]) do
        {:ok, response} ->
          status_code = extract_status_code(response)
          {{:ok, response}, Map.put(metadata, :status_code, status_code)}

        {:error, %GRPC.RPCError{} = error} ->
          result = {:error, grpc_error_to_error(error, to_string(method))}
          {result, Map.put(metadata, :status_code, error.status)}

        {:error, reason} ->
          result = {:error, connection_error(reason)}
          {result, Map.put(metadata, :status_code, GRPC.Status.unavailable())}
      end
    end)
  end

  @doc """
  Checks a Milvus Status and converts to an error if not successful.

  Many Milvus RPC calls return a Status struct. Use this function to check
  if the operation succeeded and convert to a proper error if not.

  ## Parameters

  - `status` - The `Milvex.Milvus.Proto.Common.Status` struct
  - `operation` - A string describing the operation (for error context)

  ## Returns

  - `:ok` if status indicates success (code 0)
  - `{:error, error}` if status indicates failure

  ## Examples

      case RPC.check_status(response.status, "CreateCollection") do
        :ok -> {:ok, :created}
        {:error, error} -> {:error, error}
      end
  """
  @spec check_status(Status.t() | nil, String.t()) :: :ok | {:error, Error.t()}
  def check_status(nil, operation) do
    {:error, status_to_error(nil, operation)}
  end

  def check_status(%Status{code: 0}, _operation) do
    :ok
  end

  def check_status(%Status{} = status, operation) do
    {:error, status_to_error(status, operation)}
  end

  @doc """
  Converts a Milvus proto Status to a Splode error.

  ## Parameters

  - `status` - The `Milvex.Milvus.Proto.Common.Status` struct (or nil)
  - `operation` - A string describing the operation (for error context)

  ## Returns

  A `Milvex.Error.t()` representing the status error.
  """
  @spec status_to_error(Status.t() | nil, String.t()) :: Grpc.t()
  def status_to_error(nil, operation) do
    Grpc.exception(
      operation: operation,
      code: :unknown,
      message: "Missing status in response"
    )
  end

  def status_to_error(%Status{code: code, reason: reason, detail: detail}, operation) do
    message = build_message(reason, detail)

    Grpc.exception(
      operation: operation,
      code: code,
      message: message,
      details: %{
        reason: reason,
        detail: detail
      }
    )
  end

  @doc """
  Converts a GRPC.RPCError to a Splode error.

  ## Parameters

  - `grpc_error` - The `GRPC.RPCError` struct
  - `operation` - A string describing the operation (for error context)

  ## Returns

  A `Milvex.Error.t()` representing the gRPC error.
  """
  @spec grpc_error_to_error(GRPC.RPCError.t(), String.t()) :: Grpc.t()
  def grpc_error_to_error(%GRPC.RPCError{status: status, message: message}, operation) do
    Grpc.exception(
      operation: operation,
      code: status,
      message: message || "gRPC error",
      details: %{grpc_status: status}
    )
  end

  @doc """
  Checks if a response has an embedded status field and validates it.

  Use this for responses that embed a Status struct rather than returning it directly.

  ## Examples

      response = %{status: %Status{code: 0}, collections: [...]}
      case RPC.check_response_status(response, "ShowCollections") do
        :ok -> {:ok, response}
        {:error, error} -> {:error, error}
      end
  """
  @spec check_response_status(map(), String.t()) :: :ok | {:error, Error.t()}
  def check_response_status(%{status: status}, operation) do
    check_status(status, operation)
  end

  def check_response_status(_response, _operation) do
    :ok
  end

  @doc """
  Extracts the response if status is successful, otherwise returns error.

  This is a convenience function that combines status checking with response extraction.

  ## Examples

      case RPC.with_status_check(response, "ShowCollections") do
        {:ok, response} -> {:ok, response.collection_names}
        {:error, error} -> {:error, error}
      end
  """
  @spec with_status_check(map(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def with_status_check(%{status: %Status{code: 0}} = response, _operation) do
    {:ok, response}
  end

  def with_status_check(%{status: status} = _response, operation) do
    {:error, status_to_error(status, operation)}
  end

  def with_status_check(response, _operation) when is_map(response) do
    {:ok, response}
  end

  defp connection_error(reason) do
    Connection.exception(
      reason: reason,
      retriable: retriable_error?(reason)
    )
  end

  @retriable_reasons [:timeout, :closed, :econnrefused, :econnreset, :ehostunreach, :enetunreach]

  @doc false
  @spec retriable_error?(term()) :: boolean()
  def retriable_error?(reason) when reason in @retriable_reasons, do: true
  def retriable_error?(%{reason: reason}) when reason in @retriable_reasons, do: true
  def retriable_error?("the connection is closed"), do: true
  def retriable_error?(_), do: false

  defp build_message(reason, detail) when is_binary(reason) and reason != "" do
    if is_binary(detail) and detail != "" do
      "#{reason}: #{detail}"
    else
      reason
    end
  end

  defp build_message(_reason, detail) when is_binary(detail) and detail != "" do
    detail
  end

  defp build_message(_reason, _detail) do
    "Operation failed"
  end

  defp extract_status_code(%{status: %Status{code: code}}), do: code
  defp extract_status_code(_response), do: nil
end
