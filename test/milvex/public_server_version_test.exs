defmodule Milvex.PublicServerVersionTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Milvex.Connection
  alias Milvex.Milvus.Proto.Common.Status
  alias Milvex.Milvus.Proto.Milvus.GetVersionRequest
  alias Milvex.Milvus.Proto.Milvus.GetVersionResponse
  alias Milvex.RPC

  setup :verify_on_exit!

  describe "server_version/2" do
    test "returns the parsed, cached server version and forwards detection options" do
      channel = %GRPC.Channel{ref: make_ref(), host: "localhost", port: 19_530}
      config = Milvex.Config.defaults()
      on_exit(fn -> Milvex.ServerVersion.forget(channel) end)

      stub(Connection, :get_channel, fn :fake_conn, _opts -> {:ok, channel, config} end)

      expect(RPC, :call, fn _, _, :get_version, request, opts ->
        assert %GetVersionRequest{} = request
        assert opts[:timeout] == 7_000
        {:ok, %GetVersionResponse{status: %Status{code: 0}, version: "v2.6.6"}}
      end)

      assert {:ok, %Version{major: 2, minor: 6, patch: 6}} =
               Milvex.server_version(:fake_conn, timeout: 7_000)

      assert {:ok, %Version{major: 2, minor: 6, patch: 6}} = Milvex.server_version(:fake_conn)
    end
  end
end
