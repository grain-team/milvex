defmodule Milvex.Integration.AlterCollectionSchemaTest do
  use Milvex.IntegrationCase, async: false

  alias Milvex.Schema.Field

  @moduletag :integration

  defmodule Coll do
    use Milvex.Collection

    collection do
      name "alter_schema_#{System.unique_integer([:positive])}"

      fields do
        primary_key :id, :int64, auto_id: false
        vector :embedding, 4
      end
    end
  end

  test "adds and drops a field on Milvus 3, is unsupported on older servers", %{conn: conn} do
    name = Milvex.Collection.collection_name(Coll)
    on_exit(fn -> cleanup_collection(conn, name) end)
    assert :ok = Milvex.create_collection(conn, name, Milvex.Collection.to_schema(Coll))
    assert {:ok, %Version{major: major}} = Milvex.server_version(conn)

    field = Field.scalar("extra", :int64) |> Field.nullable(true)

    if major >= 3 do
      assert :ok = Milvex.alter_collection_schema(conn, name, add_fields: [field])
      assert "extra" in field_names(conn, name)

      assert :ok = Milvex.alter_collection_schema(conn, name, drop_fields: ["extra"])
      refute "extra" in field_names(conn, name)
    else
      assert {:error, %Milvex.Errors.Grpc{code: 12}} =
               Milvex.alter_collection_schema(conn, name, add_fields: [field])
    end
  end

  defp field_names(conn, name) do
    {:ok, %{schema: schema}} = Milvex.describe_collection(conn, name)
    Enum.map(schema.fields, & &1.name)
  end
end
