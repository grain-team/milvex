defmodule Milvex.Milvus.Proto.Schema.DoubleArray do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :data, 1, repeated: true, type: :double
end
