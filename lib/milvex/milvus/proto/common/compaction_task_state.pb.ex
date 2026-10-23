defmodule Milvex.Milvus.Proto.Common.CompactionTaskState do
  @moduledoc """
  State of one compaction task, distinct from the aggregate CompactionState.
  """

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :CompactionTaskStateUnknown, 0
  field :CompactionTaskStateExecuting, 1
  field :CompactionTaskStatePipelining, 2
  field :CompactionTaskStateCompleted, 3
  field :CompactionTaskStateFailed, 4
  field :CompactionTaskStateTimeout, 5
  field :CompactionTaskStateAnalyzing, 6
  field :CompactionTaskStateIndexing, 7
  field :CompactionTaskStateCleaned, 8
  field :CompactionTaskStateMetaSaved, 9
  field :CompactionTaskStateStatistic, 10
end
