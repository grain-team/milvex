defmodule Milvex.Milvus.Proto.Milvus.ShowPartitionsResponse do
  @moduledoc """
  List all partitions for particular collection response.
  The returned datas are all rows, we can format to columns by therir index.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :partition_names, 2, repeated: true, type: :string, json_name: "partitionNames"
  field :partitionIDs, 3, repeated: true, type: :int64
  field :created_timestamps, 4, repeated: true, type: :uint64, json_name: "createdTimestamps"

  field :created_utc_timestamps, 5,
    repeated: true,
    type: :uint64,
    json_name: "createdUtcTimestamps"

  field :inMemory_percentages, 6,
    repeated: true,
    type: :int64,
    json_name: "inMemoryPercentages",
    deprecated: true
end
