defmodule Milvex.Milvus.Proto.Milvus.GetReplicateInfoResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :checkpoint, 1, type: Milvex.Milvus.Proto.Common.ReplicateCheckpoint
end
