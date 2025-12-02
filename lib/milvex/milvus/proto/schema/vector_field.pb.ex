defmodule Milvex.Milvus.Proto.Schema.VectorField do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :data, 0

  field :dim, 1, type: :int64

  field :float_vector, 2,
    type: Milvex.Milvus.Proto.Schema.FloatArray,
    json_name: "floatVector",
    oneof: 0

  field :binary_vector, 3, type: :bytes, json_name: "binaryVector", oneof: 0
  field :float16_vector, 4, type: :bytes, json_name: "float16Vector", oneof: 0
  field :bfloat16_vector, 5, type: :bytes, json_name: "bfloat16Vector", oneof: 0

  field :sparse_float_vector, 6,
    type: Milvex.Milvus.Proto.Schema.SparseFloatArray,
    json_name: "sparseFloatVector",
    oneof: 0

  field :int8_vector, 7, type: :bytes, json_name: "int8Vector", oneof: 0

  field :vector_array, 8,
    type: Milvex.Milvus.Proto.Schema.VectorArray,
    json_name: "vectorArray",
    oneof: 0
end
