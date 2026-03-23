defmodule Milvex.RetryTest do
  use ExUnit.Case, async: true

  alias Milvex.Errors.Connection, as: ConnectionError
  alias Milvex.Errors.Grpc, as: GrpcError
  alias Milvex.Errors.Invalid
  alias Milvex.Retry

  def handle_telemetry(event, measurements, metadata, pid) do
    send(pid, {:telemetry, event, measurements, metadata})
  end

  describe "retryable?/1" do
    test "retries CANCELLED (1)" do
      assert Retry.retryable?(%GrpcError{code: 1})
    end

    test "retries UNKNOWN (2)" do
      assert Retry.retryable?(%GrpcError{code: 2})
    end

    test "retries ABORTED (10)" do
      assert Retry.retryable?(%GrpcError{code: 10})
    end

    test "retries INTERNAL (13)" do
      assert Retry.retryable?(%GrpcError{code: 13})
    end

    test "retries UNAVAILABLE (14)" do
      assert Retry.retryable?(%GrpcError{code: 14})
    end

    test "does not retry INVALID_ARGUMENT (3)" do
      refute Retry.retryable?(%GrpcError{code: 3})
    end

    test "does not retry DEADLINE_EXCEEDED (4)" do
      refute Retry.retryable?(%GrpcError{code: 4})
    end

    test "does not retry NOT_FOUND (5)" do
      refute Retry.retryable?(%GrpcError{code: 5})
    end

    test "does not retry ALREADY_EXISTS (6)" do
      refute Retry.retryable?(%GrpcError{code: 6})
    end

    test "does not retry PERMISSION_DENIED (7)" do
      refute Retry.retryable?(%GrpcError{code: 7})
    end

    test "does not retry RESOURCE_EXHAUSTED (8)" do
      refute Retry.retryable?(%GrpcError{code: 8})
    end

    test "does not retry UNIMPLEMENTED (12)" do
      refute Retry.retryable?(%GrpcError{code: 12})
    end

    test "does not retry UNAUTHENTICATED (16)" do
      refute Retry.retryable?(%GrpcError{code: 16})
    end

    test "retries retriable connection errors" do
      assert Retry.retryable?(%ConnectionError{retriable: true})
    end

    test "does not retry non-retriable connection errors" do
      refute Retry.retryable?(%ConnectionError{retriable: false})
    end

    test "does not retry other error types" do
      refute Retry.retryable?(%Invalid{})
      refute Retry.retryable?(:some_error)
      refute Retry.retryable?("string error")
    end
  end

  describe "with_retry/2" do
    test "returns success immediately without retrying" do
      result = Retry.with_retry(fn -> {:ok, :done} end)

      assert {:ok, :done} = result
    end

    test "returns non-retryable error immediately" do
      error = %GrpcError{code: 3, message: "invalid"}

      result = Retry.with_retry(fn -> {:error, error} end)

      assert {:error, ^error} = result
    end

    test "retries retryable errors and succeeds" do
      counter = :counters.new(1, [:atomics])

      result =
        Retry.with_retry(
          fn ->
            count = :counters.get(counter, 1)
            :counters.add(counter, 1, 1)

            if count < 2 do
              {:error, %GrpcError{code: 13, message: "stream closed"}}
            else
              {:ok, :recovered}
            end
          end,
          retry_base_delay: 10,
          retry_max_delay: 50
        )

      assert {:ok, :recovered} = result
      assert :counters.get(counter, 1) == 3
    end

    test "stops after max attempts" do
      error = %GrpcError{code: 13, message: "stream closed"}

      result =
        Retry.with_retry(
          fn -> {:error, error} end,
          retry_max_attempts: 2,
          retry_base_delay: 10,
          retry_max_delay: 50
        )

      assert {:error, ^error} = result
    end

    test "stops when timeout exceeded" do
      error = %GrpcError{code: 13, message: "stream closed"}

      result =
        Retry.with_retry(
          fn ->
            Process.sleep(50)
            {:error, error}
          end,
          retry_max_attempts: 100,
          retry_base_delay: 10,
          retry_max_delay: 50,
          retry_timeout: 100
        )

      assert {:error, ^error} = result
    end

    test "disabled with max_attempts 0" do
      error = %GrpcError{code: 13, message: "stream closed"}

      result =
        Retry.with_retry(
          fn -> {:error, error} end,
          retry_max_attempts: 0
        )

      assert {:error, ^error} = result
    end
  end

  describe "with_retry/3 telemetry" do
    test "emits retry telemetry when retries occur" do
      test_pid = self()

      :telemetry.attach(
        "retry-test",
        [:milvex, :rpc, :retry],
        &__MODULE__.handle_telemetry/4,
        test_pid
      )

      counter = :counters.new(1, [:atomics])
      telemetry_metadata = %{method: :search, stub: :test, collection: "test_col"}

      Retry.with_retry(
        fn ->
          count = :counters.get(counter, 1)
          :counters.add(counter, 1, 1)

          if count < 2 do
            {:error, %GrpcError{code: 13, message: "stream closed"}}
          else
            {:ok, :recovered}
          end
        end,
        [retry_base_delay: 10, retry_max_delay: 50],
        telemetry_metadata
      )

      assert_received {:telemetry, [:milvex, :rpc, :retry], %{attempts: 2}, ^telemetry_metadata}
    after
      :telemetry.detach("retry-test")
    end

    test "does not emit telemetry when no retries needed" do
      test_pid = self()

      :telemetry.attach(
        "retry-no-emit-test",
        [:milvex, :rpc, :retry],
        &__MODULE__.handle_telemetry/4,
        test_pid
      )

      Retry.with_retry(
        fn -> {:ok, :done} end,
        [],
        %{method: :search}
      )

      refute_received {:telemetry, _, _, _}
    after
      :telemetry.detach("retry-no-emit-test")
    end
  end
end
