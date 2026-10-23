defmodule Milvex.Integration.NullAndGeometryTest do
  use Milvex.IntegrationCase, async: false

  alias Milvex.Milvus.Proto.Milvus.CreateCollectionRequest
  alias Milvex.Milvus.Proto.Milvus.InsertRequest
  alias Milvex.Milvus.Proto.Milvus.MilvusService
  alias Milvex.Milvus.Proto.Schema, as: ProtoSchema

  @moduletag :integration

  test "nullable scalars retain null positions in query and search", %{conn: conn} do
    name = unique_collection_name("null_readback")
    on_exit(fn -> cleanup_collection(conn, name) end)

    schema =
      Schema.build!(
        name: name,
        fields: [
          Field.primary_key("id", :int64, auto_id: false),
          Field.varchar("title", 256, nullable: true),
          Field.scalar("count", :int64, nullable: true),
          Field.timestamp("updated_at", nullable: true),
          Field.vector("embedding", 4)
        ]
      )

    assert :ok = Milvex.create_collection(conn, name, schema)

    assert :ok =
             Milvex.create_index(conn, name, "embedding",
               index_type: "AUTOINDEX",
               metric_type: "COSINE"
             )

    rows = [
      %{id: 1, title: "first", count: 10, updated_at: ~U[2025-01-01 00:00:00.000000Z]},
      %{id: 2, title: nil, count: nil, updated_at: nil},
      %{id: 3, title: "last", count: 30, updated_at: ~U[2025-06-01 00:00:00.000000Z]}
    ]

    assert {:ok, _} =
             Milvex.insert(
               conn,
               name,
               Enum.map(rows, &Map.put(&1, :embedding, [1.0, 0.0, 0.0, 0.0]))
             )

    assert :ok = Milvex.load_collection(conn, name)
    fields = ["id", "title", "count", "updated_at"]

    expected = [
      %{
        "id" => 1,
        "title" => "first",
        "count" => 10,
        "updated_at" => "2025-01-01T00:00:00Z"
      },
      %{"id" => 2, "title" => nil, "count" => nil, "updated_at" => nil},
      %{
        "id" => 3,
        "title" => "last",
        "count" => 30,
        "updated_at" => "2025-06-01T00:00:00Z"
      }
    ]

    assert {:ok, result} =
             Milvex.query(conn, name, "id >= 1",
               output_fields: fields,
               consistency_level: :Strong
             )

    assert Enum.sort_by(result.rows, & &1["id"]) == expected

    assert {:ok, %{hits: [hits]}} =
             Milvex.search(conn, name, [[1.0, 0.0, 0.0, 0.0]],
               vector_field: "embedding",
               top_k: 3,
               output_fields: fields,
               consistency_level: :Strong
             )

    assert hits |> Enum.map(& &1.fields) |> Enum.sort_by(& &1["id"]) == expected
  end

  test "Geometry reads as WKT and is described as geometry", %{conn: conn} do
    name = unique_collection_name("geometry_readback")
    on_exit(fn -> cleanup_collection(conn, name) end)

    schema = %ProtoSchema.CollectionSchema{
      name: name,
      fields: [
        %ProtoSchema.FieldSchema{name: "id", data_type: :Int64, is_primary_key: true},
        %ProtoSchema.FieldSchema{name: "location", data_type: :Geometry},
        Field.to_proto(Field.vector("embedding", 4))
      ]
    }

    assert {:ok, status} =
             Milvex.RPC.call(
               fn -> Milvex.Connection.get_channel(conn) end,
               MilvusService.Stub,
               :create_collection,
               %CreateCollectionRequest{
                 collection_name: name,
                 schema: ProtoSchema.CollectionSchema.encode(schema)
               },
               []
             )

    assert :ok = Milvex.RPC.check_status(status, "CreateCollection")
    assert {:ok, info} = Milvex.describe_collection(conn, name)
    assert %{data_type: :geometry} = Enum.find(info.schema.fields, &(&1.name == "location"))

    assert {:ok, inserted} =
             Milvex.RPC.call(
               fn -> Milvex.Connection.get_channel(conn) end,
               MilvusService.Stub,
               :insert,
               %InsertRequest{
                 collection_name: name,
                 num_rows: 2,
                 fields_data: [
                   %ProtoSchema.FieldData{
                     field_name: "id",
                     type: :Int64,
                     field:
                       {:scalars,
                        %ProtoSchema.ScalarField{
                          data: {:long_data, %ProtoSchema.LongArray{data: [1, 2]}}
                        }}
                   },
                   %ProtoSchema.FieldData{
                     field_name: "location",
                     type: :Geometry,
                     field:
                       {:scalars,
                        %ProtoSchema.ScalarField{
                          data:
                            {:geometry_wkt_data,
                             %ProtoSchema.GeometryWktArray{
                               data: ["POINT (1 2)", "LINESTRING (0 0, 1 1)"]
                             }}
                        }}
                   },
                   %ProtoSchema.FieldData{
                     field_name: "embedding",
                     type: :FloatVector,
                     field:
                       {:vectors,
                        %ProtoSchema.VectorField{
                          dim: 4,
                          data:
                            {:float_vector,
                             %ProtoSchema.FloatArray{
                               data: [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0]
                             }}
                        }}
                   }
                 ]
               },
               []
             )

    assert :ok = Milvex.RPC.check_status(inserted.status, "Insert")
    assert inserted.insert_cnt == 2

    assert :ok =
             Milvex.create_index(conn, name, "embedding",
               index_type: "AUTOINDEX",
               metric_type: "COSINE"
             )

    assert :ok = Milvex.load_collection(conn, name)

    assert {:ok, result} =
             Milvex.query(conn, name, "id >= 1",
               output_fields: ["id", "location"],
               consistency_level: :Strong
             )

    assert Enum.sort_by(result.rows, & &1["id"]) == [
             %{"id" => 1, "location" => "POINT (1 2)"},
             %{"id" => 2, "location" => "LINESTRING (0 0, 1 1)"}
           ]
  end
end
