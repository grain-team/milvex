defmodule Milvex.Milvus.Proto.Common.KeyDataPair do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :key, 1, type: :string
  field :data, 2, type: :bytes
end
