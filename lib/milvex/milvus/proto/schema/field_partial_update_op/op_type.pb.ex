defmodule Milvex.Milvus.Proto.Schema.FieldPartialUpdateOp.OpType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :REPLACE, 0
  field :ARRAY_APPEND, 1
  field :ARRAY_REMOVE, 2
end
