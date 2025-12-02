defmodule Milvex.Milvus.Proto.Schema.SearchIteratorV2Results do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :token, 1, type: :string
  field :last_bound, 2, type: :float, json_name: "lastBound"
end
