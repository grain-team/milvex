defmodule Milvex.Milvus.Proto.Common.CompactionState do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :UndefiedState, 0
  field :Executing, 1
  field :Completed, 2
end
