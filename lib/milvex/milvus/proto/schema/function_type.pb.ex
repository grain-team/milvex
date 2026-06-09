defmodule Milvex.Milvus.Proto.Schema.FunctionType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Unknown, 0
  field :BM25, 1
  field :TextEmbedding, 2
  field :Rerank, 3
end
