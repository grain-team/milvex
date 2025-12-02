defmodule Milvex.ConnectionTest do
  use ExUnit.Case, async: true

  alias Milvex.Connection

  describe "start_link/1" do
    test "fails with invalid config" do
      Process.flag(:trap_exit, true)
      result = Connection.start_link(port: -1)

      case result do
        {:error, _error} ->
          assert true

        {:ok, pid} ->
          assert_receive {:EXIT, ^pid, _reason}, 1000
      end
    end
  end

  describe "connection behavior without server" do
    @tag :integration
    test "attempting to connect to non-existent server" do
      {:ok, conn} = Connection.start_link(host: "localhost", port: 19999)

      Process.sleep(100)

      refute Connection.connected?(conn)

      Connection.disconnect(conn)
    end
  end

  describe "get_channel/1 when not connected" do
    @tag :integration
    test "returns error when not connected" do
      {:ok, conn} = Connection.start_link(host: "localhost", port: 19999)

      Process.sleep(100)

      assert {:error, error} = Connection.get_channel(conn)
      assert error.reason == :not_connected

      Connection.disconnect(conn)
    end
  end
end
