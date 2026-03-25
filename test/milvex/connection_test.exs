defmodule Milvex.ConnectionTest do
  use ExUnit.Case

  use Mimic

  alias Milvex.Connection

  setup :set_mimic_global
  setup :verify_on_exit!

  defp fake_channel(conn_pid) do
    %GRPC.Channel{
      host: "localhost",
      port: 19_530,
      adapter: GRPC.Client.Adapters.Mint,
      adapter_payload: %{conn_pid: conn_pid}
    }
  end

  defp stub_connect do
    test_pid = self()

    stub(GRPC.Stub, :connect, fn _address, _opts ->
      {:ok, agent} = Agent.start_link(fn -> :connected end)
      send(test_pid, {:connected, agent})
      {:ok, fake_channel(agent)}
    end)

    stub(GRPC.Stub, :disconnect, fn channel -> {:ok, channel} end)
  end

  defp start_and_wait do
    stub_connect()
    {:ok, conn} = Connection.start_link(host: "localhost", port: 19_530)

    conn_pid =
      receive do
        {:connected, pid} -> pid
      after
        1_000 -> raise "Timed out waiting for connection"
      end

    {conn, conn_pid}
  end

  describe "get_channel/2" do
    test "returns channel when conn_pid is alive" do
      {conn, _conn_pid} = start_and_wait()

      assert {:ok, %GRPC.Channel{}, _config} = Connection.get_channel(conn)
    end

    test "recovers when conn_pid dies" do
      {conn, conn_pid} = start_and_wait()

      Agent.stop(conn_pid)

      # Whether detected by monitor or by conn_pid_alive?, the Connection
      # should reconnect and eventually return a healthy channel
      new_conn_pid =
        receive do
          {:connected, pid} -> pid
        after
          2_000 -> raise "Timed out waiting for reconnection"
        end

      assert new_conn_pid != conn_pid
      assert {:ok, channel, _config} = Connection.get_channel(conn)
      assert channel.adapter_payload.conn_pid == new_conn_pid
    end
  end

  describe "notify_disconnected/2" do
    test "triggers reconnection when channel matches current" do
      {conn, conn_pid} = start_and_wait()

      {:ok, channel, _config} = Connection.get_channel(conn)

      :ok = Connection.notify_disconnected(conn, channel)

      new_conn_pid =
        receive do
          {:connected, pid} -> pid
        after
          2_000 -> raise "Timed out waiting for reconnection"
        end

      assert new_conn_pid != conn_pid
      assert {:ok, %GRPC.Channel{}, _config} = Connection.get_channel(conn)
    end

    test "ignores notification with stale channel" do
      {conn, conn_pid} = start_and_wait()

      stale_channel = fake_channel(spawn(fn -> Process.sleep(:infinity) end))

      :ok = Connection.notify_disconnected(conn, stale_channel)
      Process.sleep(50)

      assert Connection.connected?(conn)
      {:ok, channel, _config} = Connection.get_channel(conn)
      assert channel.adapter_payload.conn_pid == conn_pid
    end

    test "is a no-op when already reconnecting" do
      {conn, _conn_pid} = start_and_wait()

      {:ok, channel, _config} = Connection.get_channel(conn)

      :ok = Connection.notify_disconnected(conn, channel)
      :ok = Connection.notify_disconnected(conn, channel)

      _new_pid =
        receive do
          {:connected, pid} -> pid
        after
          2_000 -> raise "Timed out waiting for reconnection"
        end

      refute_receive {:connected, _}, 200
      assert Connection.connected?(conn)
    end
  end

  describe "Mint adapter opts" do
    test "adds TCP keepalive for Mint adapter" do
      test_pid = self()

      expect(GRPC.Stub, :connect, fn _address, opts ->
        send(test_pid, {:connect_opts, opts})
        {:ok, agent} = Agent.start_link(fn -> :ok end)
        {:ok, fake_channel(agent)}
      end)

      {:ok, _conn} = Connection.start_link(adapter: GRPC.Client.Adapters.Mint)

      assert_receive {:connect_opts, opts}
      adapter_opts = Keyword.get(opts, :adapter_opts, [])
      transport_opts = Keyword.get(adapter_opts, :transport_opts, [])
      assert Keyword.get(transport_opts, :keepalive) == true
    end

    test "does not override user-provided keepalive: false" do
      test_pid = self()

      expect(GRPC.Stub, :connect, fn _address, opts ->
        send(test_pid, {:connect_opts, opts})
        {:ok, agent} = Agent.start_link(fn -> :ok end)
        {:ok, fake_channel(agent)}
      end)

      {:ok, _conn} =
        Connection.start_link(
          adapter: GRPC.Client.Adapters.Mint,
          adapter_opts: [transport_opts: [keepalive: false]]
        )

      assert_receive {:connect_opts, opts}
      adapter_opts = Keyword.get(opts, :adapter_opts, [])
      transport_opts = Keyword.get(adapter_opts, :transport_opts, [])
      assert Keyword.get(transport_opts, :keepalive) == false
    end

    test "Gun adapter does not get keepalive" do
      test_pid = self()

      expect(GRPC.Stub, :connect, fn _address, opts ->
        send(test_pid, {:connect_opts, opts})
        {:ok, agent} = Agent.start_link(fn -> :ok end)
        {:ok, fake_channel(agent)}
      end)

      {:ok, _conn} = Connection.start_link(adapter: GRPC.Client.Adapters.Gun)

      assert_receive {:connect_opts, opts}
      adapter_opts = Keyword.get(opts, :adapter_opts, [])
      assert Keyword.get(adapter_opts, :retry) == 0
      refute Keyword.has_key?(adapter_opts, :transport_opts)
    end
  end
end
