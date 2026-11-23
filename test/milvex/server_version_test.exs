defmodule Milvex.ServerVersionTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Milvex.Connection
  alias Milvex.Milvus.Proto.Common.Status
  alias Milvex.Milvus.Proto.Milvus.GetVersionRequest
  alias Milvex.Milvus.Proto.Milvus.GetVersionResponse
  alias Milvex.ServerVersion

  setup :verify_on_exit!

  setup do
    %{channel: %GRPC.Channel{ref: make_ref()}, config: Milvex.Config.defaults()}
  end

  describe "detect/2" do
    test "asks the server over the given channel with a short timeout", %{
      channel: channel,
      config: config
    } do
      expect(GRPC.Stub, :call, fn _service, _rpc, stream, %GetVersionRequest{}, opts ->
        assert stream.channel == channel
        assert opts[:timeout] == 5_000
        {:ok, %GetVersionResponse{status: %Status{code: 0}, version: "v3.0.3"}}
      end)

      assert ServerVersion.detect(channel, config) == Version.parse!("3.0.3")
    end

    test "the configured version wins without an RPC", %{channel: channel, config: config} do
      version = Version.parse!("3.0.3")
      reject(GRPC.Stub, :call, 5)

      assert ServerVersion.detect(channel, %{config | server_version: version}) == version
    end

    @tag :capture_log
    test "returns nil instead of failing when detection does not yield a version", %{
      channel: channel,
      config: config
    } do
      results = [
        fn -> {:ok, %GetVersionResponse{status: %Status{code: 0}, version: "garbage"}} end,
        fn -> {:ok, %GetVersionResponse{status: %Status{code: 1, reason: "denied"}}} end,
        fn -> {:error, %GRPC.RPCError{status: 14, message: "unavailable"}} end,
        fn -> raise "boom" end,
        fn -> exit(:noproc) end
      ]

      for result <- results do
        expect(GRPC.Stub, :call, fn _, _, _, _, _ -> result.() end)
        assert ServerVersion.detect(channel, config) == nil
      end
    end
  end

  describe "get/2 and require/4" do
    test "return the version handed out with the channel", %{channel: channel, config: config} do
      version = Version.parse!("3.0.3")

      expect(Connection, :get_channel, fn :conn, [timeout: 7_000] ->
        {:ok, channel, %{config | server_version: version}}
      end)

      assert {:ok, ^version} = ServerVersion.get(:conn, timeout: 7_000)
    end

    test "unknown versions refuse features", %{channel: channel, config: config} do
      stub(Connection, :get_channel, fn :conn, _opts -> {:ok, channel, config} end)

      assert {:error, %Milvex.Errors.Invalid{code: :server_version_unknown, field: nil} = error} =
               ServerVersion.get(:conn)

      assert error.message =~ "server_version: \"x.y.z\""

      assert {:error, %Milvex.Errors.Invalid{code: :server_version_unknown, field: "feature"}} =
               ServerVersion.require(:conn, ">= 3.0.0", "feature", [])
    end

    test "requirements accept supported versions and reject older servers", %{
      channel: channel,
      config: config
    } do
      stub(Connection, :get_channel, fn conn, _opts ->
        {:ok, channel, %{config | server_version: Version.parse!(conn)}}
      end)

      assert :ok = ServerVersion.require("3.0.3", ">= 3.0.0", "feature", [])

      assert {:error,
              %Milvex.Errors.Invalid{
                code: :server_version_unsupported,
                field: "feature",
                message: "requires Milvus >= 3.0.0, connected server is 2.6.6"
              }} = ServerVersion.require("2.6.6", ">= 3.0.0", "feature", [])
    end

    test "channel lookup failures propagate" do
      error = Milvex.Errors.Connection.exception(reason: :closed)
      stub(Connection, :get_channel, fn :conn, _opts -> {:error, error} end)
      assert {:error, ^error} = ServerVersion.require(:conn, ">= 3.0.0", "feature", [])
    end
  end

  test "parses release prefixes and discards suffixes" do
    assert {:ok, %Version{major: 2, minor: 6, patch: 6}} = ServerVersion.parse("v2.6.6")

    assert {:ok, %Version{major: 3, minor: 0, patch: 4, pre: []}} =
             ServerVersion.parse("3.0.4-dev")

    assert :error = ServerVersion.parse("garbage")
  end
end
