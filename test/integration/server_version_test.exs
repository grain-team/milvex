defmodule Milvex.ServerVersionIntegrationTest do
  use Milvex.IntegrationCase

  @moduletag :integration

  test "detects the server version for the selected image", %{conn: conn} do
    image = System.get_env("MILVUS_IMAGE", "milvusdb/milvus:v2.6.6")

    expected_major =
      case image do
        "milvusdb/milvus:v2.6.6" -> 2
        "milvusdb/milvus:v3.0.3" -> 3
      end

    assert {:ok, raw_version} = Milvex.get_version(conn)

    assert {:ok, %Version{major: major} = version} = Milvex.server_version(conn)
    assert Milvex.ServerVersion.parse(raw_version) == {:ok, version}
    assert major == expected_major
    assert {:ok, ^version} = Milvex.server_version(conn)
  end
end
