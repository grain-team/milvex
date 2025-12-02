defmodule Milvex.Milvus.Proto.Common.HighlightData do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :fragments, 1, repeated: true, type: :string
end
