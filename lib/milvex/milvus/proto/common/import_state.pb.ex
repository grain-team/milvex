defmodule Milvex.Milvus.Proto.Common.ImportState do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :ImportPending, 0
  field :ImportFailed, 1
  field :ImportStarted, 2
  field :ImportPersisted, 5
  field :ImportFlushed, 8
  field :ImportCompleted, 6
  field :ImportFailedAndCleaned, 7
end
