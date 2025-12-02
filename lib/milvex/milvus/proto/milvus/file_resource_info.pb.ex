defmodule Milvex.Milvus.Proto.Milvus.FileResourceInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :int64
  field :name, 2, type: :string
  field :path, 3, type: :string
end
