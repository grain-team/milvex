defmodule Milvex.Milvus.Proto.Milvus.DummyResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :response, 1, type: :string
end
