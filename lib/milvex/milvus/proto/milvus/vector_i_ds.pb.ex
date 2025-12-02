defmodule Milvex.Milvus.Proto.Milvus.VectorIDs do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :collection_name, 1, type: :string, json_name: "collectionName"
  field :field_name, 2, type: :string, json_name: "fieldName"
  field :id_array, 3, type: Milvex.Milvus.Proto.Schema.IDs, json_name: "idArray"
  field :partition_names, 4, repeated: true, type: :string, json_name: "partitionNames"
end
