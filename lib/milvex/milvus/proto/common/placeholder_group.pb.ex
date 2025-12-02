defmodule Milvex.Milvus.Proto.Common.PlaceholderGroup do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :placeholders, 1, repeated: true, type: Milvex.Milvus.Proto.Common.PlaceholderValue
end
