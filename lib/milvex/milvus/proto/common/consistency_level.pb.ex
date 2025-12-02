defmodule Milvex.Milvus.Proto.Common.ConsistencyLevel do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Strong, 0
  field :Session, 1
  field :Bounded, 2
  field :Eventually, 3
  field :Customized, 4
end
