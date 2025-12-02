defmodule Milvex.Milvus.Proto.Schema.VectorArray do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :dim, 1, type: :int64
  field :data, 2, repeated: true, type: Milvex.Milvus.Proto.Schema.VectorField

  field :element_type, 3,
    type: Milvex.Milvus.Proto.Schema.DataType,
    json_name: "elementType",
    enum: true
end
