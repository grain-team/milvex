defmodule Milvex.Milvus.Proto.Common.Address do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :ip, 1, type: :string
  field :port, 2, type: :int64
end
