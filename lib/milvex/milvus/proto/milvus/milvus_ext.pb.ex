defmodule Milvex.Milvus.Proto.Milvus.MilvusExt do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :version, 1, type: :string
end
