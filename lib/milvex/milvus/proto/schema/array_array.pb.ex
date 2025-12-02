defmodule Milvex.Milvus.Proto.Schema.ArrayArray do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :data, 1, repeated: true, type: Milvex.Milvus.Proto.Schema.ScalarField

  field :element_type, 2,
    type: Milvex.Milvus.Proto.Schema.DataType,
    json_name: "elementType",
    enum: true
end
