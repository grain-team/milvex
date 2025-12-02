defmodule Milvex.Milvus.Proto.Milvus.VectorsArray do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :array, 0

  field :id_array, 1, type: Milvex.Milvus.Proto.Milvus.VectorIDs, json_name: "idArray", oneof: 0

  field :data_array, 2,
    type: Milvex.Milvus.Proto.Schema.VectorField,
    json_name: "dataArray",
    oneof: 0
end
