defmodule Milvex.Milvus.Proto.Tokenizer.TokenizationRequest.Parameter do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :key, 1, type: :string
  field :values, 2, repeated: true, type: :string
end
