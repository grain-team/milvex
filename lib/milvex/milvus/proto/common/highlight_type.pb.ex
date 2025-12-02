defmodule Milvex.Milvus.Proto.Common.HighlightType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Lexical, 0
  field :Semantic, 1
end
