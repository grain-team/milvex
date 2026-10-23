defmodule Milvex.Milvus.Proto.Milvus.ElementIndices do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :indices, 1, type: Milvex.Milvus.Proto.Schema.LongArray
end
