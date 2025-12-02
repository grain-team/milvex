defmodule Milvex.Milvus.Proto.Common.LoadPriority do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :HIGH, 0
  field :LOW, 1
end
