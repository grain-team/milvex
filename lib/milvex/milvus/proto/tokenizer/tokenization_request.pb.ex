defmodule Milvex.Milvus.Proto.Tokenizer.TokenizationRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :text, 1, type: :string

  field :parameters, 2,
    repeated: true,
    type: Milvex.Milvus.Proto.Tokenizer.TokenizationRequest.Parameter
end
