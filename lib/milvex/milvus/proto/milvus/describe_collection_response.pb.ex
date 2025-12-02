defmodule Milvex.Milvus.Proto.Milvus.DescribeCollectionResponse do
  @moduledoc """
  *
  DescribeCollection Response
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :schema, 2, type: Milvex.Milvus.Proto.Schema.CollectionSchema
  field :collectionID, 3, type: :int64
  field :virtual_channel_names, 4, repeated: true, type: :string, json_name: "virtualChannelNames"

  field :physical_channel_names, 5,
    repeated: true,
    type: :string,
    json_name: "physicalChannelNames"

  field :created_timestamp, 6, type: :uint64, json_name: "createdTimestamp"
  field :created_utc_timestamp, 7, type: :uint64, json_name: "createdUtcTimestamp"
  field :shards_num, 8, type: :int32, json_name: "shardsNum"
  field :aliases, 9, repeated: true, type: :string

  field :start_positions, 10,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyDataPair,
    json_name: "startPositions"

  field :consistency_level, 11,
    type: Milvex.Milvus.Proto.Common.ConsistencyLevel,
    json_name: "consistencyLevel",
    enum: true

  field :collection_name, 12, type: :string, json_name: "collectionName"
  field :properties, 13, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
  field :db_name, 14, type: :string, json_name: "dbName"
  field :num_partitions, 15, type: :int64, json_name: "numPartitions"
  field :db_id, 16, type: :int64, json_name: "dbId"
  field :request_time, 17, type: :uint64, json_name: "requestTime"
  field :update_timestamp, 18, type: :uint64, json_name: "updateTimestamp"
  field :update_timestamp_str, 19, type: :string, json_name: "updateTimestampStr"
end
