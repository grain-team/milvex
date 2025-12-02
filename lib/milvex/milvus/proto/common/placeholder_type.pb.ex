defmodule Milvex.Milvus.Proto.Common.PlaceholderType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :None, 0
  field :BinaryVector, 100
  field :FloatVector, 101
  field :Float16Vector, 102
  field :BFloat16Vector, 103
  field :SparseFloatVector, 104
  field :Int8Vector, 105
  field :Int64, 5
  field :VarChar, 21
  field :EmbListBinaryVector, 300
  field :EmbListFloatVector, 301
  field :EmbListFloat16Vector, 302
  field :EmbListBFloat16Vector, 303
  field :EmbListSparseFloatVector, 304
  field :EmbListInt8Vector, 305
end
