defmodule Milvex.Milvus.Proto.Common.CompactionType do
  @moduledoc """
  Type of one compaction task.
  """

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :CompactionTypeUndefined, 0
  field :CompactionTypeMerge, 2
  field :CompactionTypeMix, 3
  field :CompactionTypeSingle, 4
  field :CompactionTypeMinor, 5
  field :CompactionTypeMajor, 6
  field :CompactionTypeLevel0Delete, 7
  field :CompactionTypeClustering, 8
  field :CompactionTypeSort, 9
  field :CompactionTypePartitionKeySort, 10
  field :CompactionTypeClusteringPartitionKeySort, 11
  field :CompactionTypeBumpSchemaVersion, 12
end
