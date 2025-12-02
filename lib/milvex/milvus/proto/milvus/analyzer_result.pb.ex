defmodule Milvex.Milvus.Proto.Milvus.AnalyzerResult do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :tokens, 1, repeated: true, type: Milvex.Milvus.Proto.Milvus.AnalyzerToken
end
