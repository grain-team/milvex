defmodule Milvex.ConnectionPoolTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Milvex.Config
  alias Milvex.Connection
  alias Milvex.ConnectionPool
  alias Milvex.Errors

  @moduletag :capture_log

  setup :set_mimic_global

  describe "get_channel/2" do
    test "round-robins channels across pooled connections" do
      stub_successful_connect()

      {:ok, pool} = ConnectionPool.start_link(host: "localhost", pool_size: 3)

      eventually(fn ->
        pids = for _ <- 1..3, do: channel_pid!(pool)
        assert pids |> Enum.uniq() |> length() == 3
      end)

      first_cycle = for _ <- 1..3, do: channel_pid!(pool)
      second_cycle = for _ <- 1..3, do: channel_pid!(pool)

      assert first_cycle == second_cycle
    end

    test "returns retriable not_connected error when no connection is up" do
      stub(GRPC.Stub, :connect, fn _address, _opts -> {:error, :econnrefused} end)

      {:ok, pool} = ConnectionPool.start_link(host: "localhost", pool_size: 2)

      assert {:error, %Errors.Connection{reason: :not_connected, retriable: true}} =
               ConnectionPool.get_channel(pool)

      refute ConnectionPool.connected?(pool)
    end
  end

  describe "Milvex.Connection protocol compatibility" do
    test "start_link with pool_size > 1 starts a pool usable through Connection" do
      stub_successful_connect()

      {:ok, pool} = Connection.start_link(host: "localhost", pool_size: 2, name: :pool_compat)

      eventually(fn ->
        assert {:ok, %GRPC.Channel{}, config} = Connection.get_channel(:pool_compat)
        assert config.pool_size == 2
        assert Connection.connected?(:pool_compat)
      end)

      :ok = Connection.disconnect(pool)
      refute Process.alive?(pool)
    end
  end

  describe "config" do
    test "pool_size defaults to 1" do
      assert {:ok, %{pool_size: 1}} = Config.parse(%{})
    end

    test "rejects pool_size below 1" do
      assert {:error, %Errors.Invalid{}} = Config.parse(pool_size: 0)
    end
  end

  defp stub_successful_connect do
    GRPC.Stub
    |> stub(:connect, fn _address, _opts ->
      conn_pid = spawn(fn -> Process.sleep(:infinity) end)
      {:ok, %GRPC.Channel{adapter_payload: %{conn_pid: conn_pid}}}
    end)
    |> stub(:disconnect, fn channel ->
      Process.exit(channel.adapter_payload.conn_pid, :kill)
      {:ok, channel}
    end)
  end

  defp channel_pid!(pool) do
    {:ok, channel, _config} = Connection.get_channel(pool)
    channel.adapter_payload.conn_pid
  end

  defp eventually(fun, attempts \\ 50) do
    fun.()
  rescue
    error in [ExUnit.AssertionError, MatchError] ->
      if attempts > 0 do
        Process.sleep(20)
        eventually(fun, attempts - 1)
      else
        reraise error, __STACKTRACE__
      end
  end
end
