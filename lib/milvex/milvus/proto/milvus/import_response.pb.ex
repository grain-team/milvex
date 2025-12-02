defmodule Milvex.Milvus.Proto.Milvus.ImportResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :tasks, 2, repeated: true, type: :int64
end
