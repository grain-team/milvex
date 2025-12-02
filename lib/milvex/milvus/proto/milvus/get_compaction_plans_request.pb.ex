defmodule Milvex.Milvus.Proto.Milvus.GetCompactionPlansRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :compactionID, 1, type: :int64
end
