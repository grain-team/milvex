defmodule Milvex.Milvus.Proto.Common.DslType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Dsl, 0
  field :BoolExprV1, 1
end
