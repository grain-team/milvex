defmodule Milvex.Milvus.Proto.Common.ReplicateInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :isReplicate, 1, type: :bool
  field :msgTimestamp, 2, type: :uint64
  field :replicateID, 3, type: :string
end
