defmodule Milvex.Milvus.Proto.Milvus.PrewarmTaskState do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :PrewarmTaskStateUnknown, 0
  field :PrewarmTaskStatePending, 1
  field :PrewarmTaskStateWarming, 2
  field :PrewarmTaskStateCompleted, 3
  field :PrewarmTaskStateFailed, 4
end
