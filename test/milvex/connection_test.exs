defmodule Milvex.ConnectionTest do
  use ExUnit.Case, async: true

  alias Milvex.Connection

  defp connected_data(conn_pid) do
    channel = %GRPC.Channel{
      host: "localhost",
      port: 19_530,
      adapter_payload: %{conn_pid: conn_pid}
    }

    %Connection{
      config: Milvex.Config.defaults(),
      channel: channel,
      conn_monitor_ref: nil,
      retry_count: 0
    }
  end

  defp dead_pid do
    pid = spawn(fn -> :ok end)
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, ^pid, _reason}
    pid
  end

  describe "connected/3 disconnect messages" do
    test "reconnects on connection_down from the current connection process" do
      conn_pid = dead_pid()
      data = connected_data(conn_pid)

      assert {:next_state, :reconnecting, %Connection{channel: nil}} =
               Connection.connected(:info, {:elixir_grpc, :connection_down, conn_pid}, data)
    end

    test "ignores connection_down from a stale connection process" do
      data = connected_data(self())

      assert :keep_state_and_data =
               Connection.connected(:info, {:elixir_grpc, :connection_down, dead_pid()}, data)
    end

    test "reconnects on gun_down from the current connection process" do
      conn_pid = dead_pid()
      data = connected_data(conn_pid)

      assert {:next_state, :reconnecting, %Connection{channel: nil}} =
               Connection.connected(:info, {:gun_down, conn_pid, :http2, :closed, []}, data)
    end

    test "ignores gun_down from a stale connection process" do
      data = connected_data(self())

      assert :keep_state_and_data =
               Connection.connected(:info, {:gun_down, dead_pid(), :http2, :closed, []}, data)
    end
  end
end
