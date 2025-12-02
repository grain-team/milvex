defmodule Milvex.Milvus.Proto.Common.ObjectType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Collection, 0
  field :Global, 1
  field :User, 2
end
