defmodule Milvex.Retry do
  @moduledoc """
  RPC-level retry logic for transient gRPC errors.

  Wraps gRPC calls with exponential backoff, retrying on transient failures
  like stream closures (INTERNAL) and server unavailability (UNAVAILABLE).

  ## Retryable gRPC status codes

  Only the following transient gRPC status codes are retried:

  | Code | Name              | Reason |
  |------|-------------------|--------|
  | 1    | CANCELLED         | Request cancelled, safe to retry |
  | 2    | UNKNOWN           | Unknown server error, may be transient |
  | 10   | ABORTED           | Operation aborted, typically retriable |
  | 13   | INTERNAL          | Server-side error (e.g., stream closures) |
  | 14   | UNAVAILABLE       | Server temporarily unavailable |

  ## Configuration

  Retry behavior is configured via `Milvex.Config`:

  - `:retry_max_attempts` - Maximum number of retry attempts (default: 5)
  - `:retry_base_delay` - Initial backoff delay in ms (default: 100)
  - `:retry_max_delay` - Maximum backoff delay in ms (default: 3000)
  - `:retry_timeout` - Total retry time budget in ms (default: 15000)

  Per-call overrides can be passed through `RPC.call/5` opts.
  """

  require Logger

  alias Milvex.Backoff
  alias Milvex.Errors.Connection, as: ConnectionError
  alias Milvex.Errors.Grpc, as: GrpcError

  @retryable_grpc_codes [
    1,
    2,
    10,
    13,
    14
  ]

  @default_max_attempts 5
  @default_base_delay 100
  @default_max_delay 3_000
  @default_timeout 15_000

  @type retry_opts :: [
          retry_max_attempts: non_neg_integer(),
          retry_base_delay: pos_integer(),
          retry_max_delay: pos_integer(),
          retry_timeout: pos_integer()
        ]

  @doc """
  Executes a function with retry logic for transient errors.

  The function is called immediately. If it returns `{:error, error}` and
  the error is retryable, it sleeps with exponential backoff and retries.

  Retries stop when any of these conditions are met:
  - The function returns `{:ok, _}`
  - The error is non-retryable
  - Max attempts exceeded
  - Total timeout exceeded

  When `telemetry_metadata` is provided and retries occur, emits a
  `[:milvex, :rpc, :retry]` telemetry event with `%{attempts: n}` measurements.

  ## Options

  - `:retry_max_attempts` - Max retries (default: #{@default_max_attempts})
  - `:retry_base_delay` - Initial delay in ms (default: #{@default_base_delay})
  - `:retry_max_delay` - Max delay in ms (default: #{@default_max_delay})
  - `:retry_timeout` - Total time budget in ms (default: #{@default_timeout})
  """
  @spec with_retry(
          (-> {:ok, term()} | {:error, term()}),
          retry_opts(),
          map() | nil
        ) :: {:ok, term()} | {:error, term()}
  def with_retry(fun, opts \\ [], telemetry_metadata \\ nil) when is_function(fun, 0) do
    max_attempts = Keyword.get(opts, :retry_max_attempts, @default_max_attempts)
    base_delay = Keyword.get(opts, :retry_base_delay, @default_base_delay)
    max_delay = Keyword.get(opts, :retry_max_delay, @default_max_delay)
    timeout = Keyword.get(opts, :retry_timeout, @default_timeout)
    start_time = System.monotonic_time(:millisecond)

    result = do_retry(fun, 0, max_attempts, base_delay, max_delay, timeout, start_time)
    {attempt_count, result} = result

    if attempt_count > 0 and telemetry_metadata do
      emit_retry_telemetry(telemetry_metadata, attempt_count)
    end

    result
  end

  @doc """
  Returns whether an error is retryable.
  """
  @spec retryable?(term()) :: boolean()
  def retryable?(%GrpcError{code: code}) when code in @retryable_grpc_codes, do: true
  def retryable?(%GrpcError{}), do: false
  def retryable?(%ConnectionError{retriable: true}), do: true
  def retryable?(_), do: false

  @doc """
  Extracts retry-specific options from a keyword list.

  Returns `{retry_opts, remaining_opts}`.
  """
  @spec split_opts(keyword()) :: {retry_opts(), keyword()}
  def split_opts(opts) do
    Keyword.split(opts, [
      :retry_max_attempts,
      :retry_base_delay,
      :retry_max_delay,
      :retry_timeout
    ])
  end

  defp do_retry(fun, attempt, max_attempts, base_delay, max_delay, timeout, start_time) do
    case fun.() do
      {:error, error} when attempt < max_attempts ->
        maybe_retry(fun, error, attempt, max_attempts, base_delay, max_delay, timeout, start_time)

      result ->
        {attempt, result}
    end
  end

  defp maybe_retry(fun, error, attempt, max_attempts, base_delay, max_delay, timeout, start_time) do
    elapsed = System.monotonic_time(:millisecond) - start_time
    delay = compute_delay(attempt, base_delay, max_delay, timeout, elapsed)

    if retryable?(error) and delay > 0 do
      maybe_log_retry(attempt, delay)
      Process.sleep(delay)
      do_retry(fun, attempt + 1, max_attempts, base_delay, max_delay, timeout, start_time)
    else
      {attempt, {:error, error}}
    end
  end

  defp compute_delay(attempt, base_delay, max_delay, timeout, elapsed) when elapsed < timeout do
    delay = Backoff.calculate(attempt, base_delay, max_delay)
    remaining = timeout - elapsed
    min(delay, remaining)
  end

  defp compute_delay(_attempt, _base_delay, _max_delay, _timeout, _elapsed), do: 0

  defp maybe_log_retry(attempt, delay) when attempt >= 2 do
    Logger.info("RPC retry attempt #{attempt + 1}, backoff #{delay}ms")
  end

  defp maybe_log_retry(_attempt, _delay), do: :ok

  defp emit_retry_telemetry(metadata, attempts) do
    :telemetry.execute(
      [:milvex, :rpc, :retry],
      %{attempts: attempts},
      metadata
    )
  end
end
