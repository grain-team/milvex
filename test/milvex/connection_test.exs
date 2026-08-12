defmodule Milvex.ConnectionTest do
  # Global Mimic mode: GRPC.Stub calls happen inside the Connection process.
  use ExUnit.Case, async: false
  use Mimic

  alias Milvex.Connection

  setup :set_mimic_global

  @conn_opts [host: "localhost", port: 19_530]

  defp fake_gun(test_pid) do
    spawn(fn ->
      receive do
        msg -> send(test_pid, {:gun_received, msg})
      end
    end)
  end

  defp fake_wrapper(gun_pid) do
    # :sys.get_state/1 on an Agent returns the agent state, mirroring the
    # grpc 1.0 Gun ConnectionProcess state shape (%{gun_pid: pid, ...}).
    {:ok, wrapper} = Agent.start(fn -> %{gun_pid: gun_pid, response_processes: %{}} end)
    wrapper
  end

  defp fake_channel(wrapper_pid) do
    %GRPC.Channel{
      host: "localhost",
      port: 19_530,
      scheme: "http",
      adapter: GRPC.Client.Adapters.Gun,
      adapter_payload: %{conn_pid: wrapper_pid}
    }
  end

  defp wait_until(fun, timeout \\ 1_000) do
    deadline = System.monotonic_time(:millisecond) + timeout

    Stream.repeatedly(fn ->
      fun.() || (System.monotonic_time(:millisecond) < deadline && Process.sleep(10))
    end)
    |> Enum.find(&(&1 == true)) || flunk("condition not met within #{timeout}ms")
  end

  describe "gun adapter connection options" do
    test "defaults to retry: 0 with HTTP/2 keepalive enabled" do
      test_pid = self()

      stub(GRPC.Stub, :connect, fn _addr, opts ->
        send(test_pid, {:connect_opts, opts})
        {:error, :refused}
      end)

      {:ok, _conn} = Connection.start_link(@conn_opts)

      assert_receive {:connect_opts, opts}, 1_000
      adapter_opts = Keyword.fetch!(opts, :adapter_opts)
      assert adapter_opts[:retry] == 0
      assert adapter_opts[:http2_opts] == %{keepalive: 30_000, keepalive_tolerance: 2}
    end

    test "user adapter_opts override the defaults" do
      test_pid = self()

      stub(GRPC.Stub, :connect, fn _addr, opts ->
        send(test_pid, {:connect_opts, opts})
        {:error, :refused}
      end)

      {:ok, _conn} =
        Connection.start_link(
          @conn_opts ++ [adapter_opts: [retry: 5, http2_opts: %{keepalive: 5_000}]]
        )

      assert_receive {:connect_opts, opts}, 1_000
      adapter_opts = Keyword.fetch!(opts, :adapter_opts)
      assert adapter_opts[:retry] == 5
      assert adapter_opts[:http2_opts] == %{keepalive: 5_000, keepalive_tolerance: 2}
    end
  end

  describe "gun process monitoring" do
    test "gun death is detected, the zombie wrapper is closed, and reconnection starts" do
      test_pid = self()
      gun = fake_gun(test_pid)
      wrapper = fake_wrapper(gun)
      channel = fake_channel(wrapper)

      GRPC.Stub
      |> stub(:connect, fn _addr, _opts ->
        send(test_pid, :reconnect_attempted)
        {:error, :refused}
      end)
      |> expect(:connect, fn _addr, _opts -> {:ok, channel} end)
      |> stub(:disconnect, fn ch ->
        send(test_pid, :wrapper_disconnected)
        {:ok, ch}
      end)

      {:ok, conn} = Connection.start_link(@conn_opts)
      wait_until(fn -> Connection.connected?(conn) end)

      # Connection drop with retry: 0 -> gun dies, wrapper stays alive (zombie)
      Process.exit(gun, :kill)

      assert_receive :wrapper_disconnected, 1_000
      assert_receive :reconnect_attempted, 1_000
      refute Connection.connected?(conn)
      assert Process.alive?(wrapper)
    end

    test "wrapper death shuts down the orphaned gun process and reconnects" do
      test_pid = self()
      gun = fake_gun(test_pid)
      wrapper = fake_wrapper(gun)
      channel = fake_channel(wrapper)

      GRPC.Stub
      |> stub(:connect, fn _addr, _opts ->
        send(test_pid, :reconnect_attempted)
        {:error, :refused}
      end)
      |> expect(:connect, fn _addr, _opts -> {:ok, channel} end)

      {:ok, conn} = Connection.start_link(@conn_opts)
      wait_until(fn -> Connection.connected?(conn) end)

      Process.exit(wrapper, :kill)

      # Orphaned gun receives the shutdown cast
      assert_receive {:gun_received, _shutdown}, 1_000
      assert_receive :reconnect_attempted, 1_000
      refute Connection.connected?(conn)
    end

    test "still connects when the gun pid cannot be resolved from the wrapper" do
      test_pid = self()
      {:ok, wrapper} = Agent.start(fn -> %{unexpected: :state} end)
      channel = fake_channel(wrapper)

      GRPC.Stub
      |> stub(:connect, fn _addr, _opts ->
        send(test_pid, :reconnect_attempted)
        {:error, :refused}
      end)
      |> expect(:connect, fn _addr, _opts -> {:ok, channel} end)

      {:ok, conn} = Connection.start_link(@conn_opts)
      wait_until(fn -> Connection.connected?(conn) end)

      # Falls back to wrapper-only monitoring
      Process.exit(wrapper, :kill)
      assert_receive :reconnect_attempted, 1_000
      refute Connection.connected?(conn)
    end
  end
end
