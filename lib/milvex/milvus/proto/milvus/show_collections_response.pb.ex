defmodule Milvex.Milvus.Proto.Milvus.ShowCollectionsResponse do
  @moduledoc """
  Return basic collection infos.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :collection_names, 2, repeated: true, type: :string, json_name: "collectionNames"
  field :collection_ids, 3, repeated: true, type: :int64, json_name: "collectionIds"
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

  field :query_service_available, 7,
    repeated: true,
    type: :bool,
    json_name: "queryServiceAvailable"

  field :shards_num, 8, repeated: true, type: :int32, json_name: "shardsNum"
end
