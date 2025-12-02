defmodule Milvex.Milvus.Proto.Msg.ImportFile do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :int64
  field :paths, 2, repeated: true, type: :string
end
