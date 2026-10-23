defmodule Milvex.ConfigServerVersionTest do
  use ExUnit.Case, async: true

  alias Milvex.Config
  alias Milvex.Errors.Invalid

  test "re-parses a normalized config preserving its server version" do
    assert {:ok, config} = Config.parse(server_version: "3.0.4")
    assert %Version{} = version = config.server_version
    assert {:ok, %{server_version: ^version}} = Config.parse(config)
  end

  test "normalizes an optional server version and rejects invalid overrides" do
    assert {:ok, %{server_version: nil}} = Config.parse([])

    assert {:ok, %{server_version: %Version{major: 3, minor: 0, patch: 4}}} =
             Config.parse(server_version: "3.0.4")

    assert {:error, %Invalid{field: "config"}} = Config.parse(server_version: "nope")
    assert {:error, %Invalid{field: "config"}} = Config.parse(server_version: 3)
  end
end
