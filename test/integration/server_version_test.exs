defmodule Milvex.ServerVersionIntegrationTest do
  use Milvex.IntegrationCase

  @moduletag :integration

  test "detects the server version for the selected image", %{conn: conn} do
    image = System.get_env("MILVUS_IMAGE", "milvusdb/milvus:v2.6.6")

    assert [major_tag] = Regex.run(~r/:v?(\d+)\./, image, capture: :all_but_first)
    expected_major = String.to_integer(major_tag)

    assert {:ok, raw_version} = Milvex.get_version(conn)

    assert {:ok, %Version{major: major} = version} = Milvex.server_version(conn)
    assert Milvex.ServerVersion.parse(raw_version) == {:ok, version}
    assert major == expected_major
    assert {:ok, ^version} = Milvex.server_version(conn)
  end
end
