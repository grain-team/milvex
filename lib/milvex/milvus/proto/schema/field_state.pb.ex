defmodule Milvex.Milvus.Proto.Schema.FieldState do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :FieldCreated, 0
  field :FieldCreating, 1
  field :FieldDropping, 2
  field :FieldDropped, 3
end
