defmodule Milvex.Milvus.Proto.Common.Blob do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :value, 1, type: :bytes
end
