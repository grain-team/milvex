defmodule Milvex.Milvus.Proto.Common.OrderSpec do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :key, 1, type: :string
  field :direction, 2, type: :string
  field :null_first, 3, type: :bool, json_name: "nullFirst"
end
