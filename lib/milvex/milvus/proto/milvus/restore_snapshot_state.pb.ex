defmodule Milvex.Milvus.Proto.Milvus.RestoreSnapshotState do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :RestoreSnapshotNone, 0
  field :RestoreSnapshotPending, 1
  field :RestoreSnapshotExecuting, 2
  field :RestoreSnapshotCompleted, 3
  field :RestoreSnapshotFailed, 4
end
