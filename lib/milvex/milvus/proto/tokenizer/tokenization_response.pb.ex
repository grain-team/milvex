defmodule Milvex.Milvus.Proto.Tokenizer.TokenizationResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :tokens, 1, repeated: true, type: Milvex.Milvus.Proto.Tokenizer.Token
end
