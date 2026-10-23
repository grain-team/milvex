defmodule Milvex.Milvus.Proto.Milvus.ExportSnapshotState do
  @moduledoc """
  Async snapshot export job state and query APIs.
  """

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :ExportSnapshotNone, 0
  field :ExportSnapshotPending, 1
  field :ExportSnapshotExecuting, 2
  field :ExportSnapshotCompleted, 3
  field :ExportSnapshotFailed, 4
end
