defmodule Milvex.Milvus.Proto.Milvus.ObjectEntity do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :name, 1, type: :string
end
