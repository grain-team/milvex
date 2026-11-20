defmodule Milvex.ServerVersionTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Milvex.Connection
  alias Milvex.Milvus.Proto.Common.Status
  alias Milvex.Milvus.Proto.Milvus.GetVersionRequest
  alias Milvex.Milvus.Proto.Milvus.GetVersionResponse
  alias Milvex.Milvus.Proto.Milvus.MilvusService
  alias Milvex.RPC
  alias Milvex.ServerVersion

  setup :verify_on_exit!

  setup do
    channel = %GRPC.Channel{ref: make_ref()}
    config = Milvex.Config.defaults()
    stub(Connection, :get_channel, fn :conn, _opts -> {:ok, channel, config} end)
    %{channel: channel, config: config}
  end

  test "detects the version and reports it to the connection", %{
    channel: channel,
    config: config
  } do
    expect(RPC, :call, fn channel_fn,
                          MilvusService.Stub,
                          :get_version,
                          %GetVersionRequest{},
                          opts ->
      assert {:ok, ^channel, ^config} = channel_fn.()
      assert opts[:timeout] == 7_000
      {:ok, %GetVersionResponse{status: %Status{code: 0}, version: "v3.0.3"}}
    end)

    version = Version.parse!("3.0.3")
    expect(Connection, :put_server_version, fn :conn, ^channel, ^version -> :ok end)

    assert {:ok, ^version} = ServerVersion.get(:conn, timeout: 7_000)
  end

  test "detection uses the connection timeout and retry settings", %{
    channel: channel,
    config: config
  } do
    config = %{config | timeout: 12_000, retry_max_attempts: 2}
    stub(Connection, :get_channel, fn :conn, _opts -> {:ok, channel, config} end)

    expect(RPC, :call, fn channel_fn, _, :get_version, _, opts ->
      assert {:ok, ^channel, ^config} = channel_fn.()
      assert opts[:timeout] == 12_000
      assert opts[:retry_max_attempts] == 2
      {:ok, %GetVersionResponse{status: %Status{code: 0}, version: "v3.0.3"}}
    end)

    assert {:ok, %Version{major: 3}} = ServerVersion.get(:conn)
  end

  test "a version in the channel config skips detection", %{channel: channel, config: config} do
    version = Version.parse!("3.0.3")

    stub(Connection, :get_channel, fn :conn, _opts ->
      {:ok, channel, Map.put(config, :server_version, version)}
    end)

    reject(RPC, :call, 5)
    assert {:ok, ^version} = ServerVersion.get(:conn)
  end

  test "unparseable versions refuse features and are not remembered" do
    reject(Connection, :put_server_version, 3)

    expect(RPC, :call, 2, fn _, _, :get_version, _, _ ->
      {:ok, %GetVersionResponse{status: %Status{code: 0}, version: "garbage"}}
    end)

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
    stub(Connection, :get_channel, fn :conn, _opts ->
      {:ok, channel, %{config | server_version: Version.parse!("3.0.3")}}
    end)

    assert :ok = ServerVersion.require(:conn, ">= 3.0.0", "feature", [])

    stub(Connection, :get_channel, fn :conn, _opts ->
      {:ok, channel, %{config | server_version: Version.parse!("2.6.6")}}
    end)

    assert {:error,
            %Milvex.Errors.Invalid{
              code: :server_version_unsupported,
              field: "feature",
              message: "requires Milvus >= 3.0.0, connected server is 2.6.6"
            }} = ServerVersion.require(:conn, ">= 3.0.0", "feature", [])
  end

  test "failed detection is returned unchanged and retried" do
    error = Milvex.Errors.Connection.exception(reason: :timeout)
    expect(RPC, :call, fn _, _, :get_version, _, _ -> {:error, error} end)
    assert {:error, ^error} = ServerVersion.get(:conn)

    expect(RPC, :call, fn _, _, :get_version, _, _ ->
      {:ok, %GetVersionResponse{status: %Status{code: 0}, version: "v2.6.6"}}
    end)

    assert {:ok, %Version{major: 2, minor: 6, patch: 6}} = ServerVersion.get(:conn)
  end

  test "Milvus status failures are not remembered" do
    reject(Connection, :put_server_version, 3)

    expect(RPC, :call, fn _, _, :get_version, _, _ ->
      {:ok, %GetVersionResponse{status: %Status{code: 1, reason: "denied"}, version: "v3.0.3"}}
    end)

    assert {:error, %Milvex.Errors.Grpc{}} = ServerVersion.get(:conn)
  end

  test "channel lookup failures propagate without an RPC" do
    error = Milvex.Errors.Connection.exception(reason: :closed)
    stub(Connection, :get_channel, fn :conn, _opts -> {:error, error} end)
    reject(RPC, :call, 5)
    assert {:error, ^error} = ServerVersion.require(:conn, ">= 3.0.0", "feature", [])
  end

  test "parses release prefixes and discards suffixes" do
    assert {:ok, %Version{major: 2, minor: 6, patch: 6}} = ServerVersion.parse("v2.6.6")

    assert {:ok, %Version{major: 3, minor: 0, patch: 4, pre: []}} =
             ServerVersion.parse("3.0.4-dev")

    assert :error = ServerVersion.parse("garbage")
  end
end
