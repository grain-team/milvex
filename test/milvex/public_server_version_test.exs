defmodule Milvex.PublicServerVersionTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Milvex.Connection
  alias Milvex.RPC

  setup :verify_on_exit!

  describe "server_version/2" do
    test "returns the version detected by the connection without an RPC" do
      channel = %GRPC.Channel{ref: make_ref(), host: "localhost", port: 19_530}
      config = %{Milvex.Config.defaults() | server_version: Version.parse!("2.6.6")}

      expect(Connection, :get_channel, fn :fake_conn, [timeout: 7_000] ->
        {:ok, channel, config}
      end)

      reject(RPC, :call, 5)

      assert {:ok, %Version{major: 2, minor: 6, patch: 6}} =
               Milvex.server_version(:fake_conn, timeout: 7_000)
    end
  end
end
