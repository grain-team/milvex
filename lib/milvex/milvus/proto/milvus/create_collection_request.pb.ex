defmodule Milvex.Milvus.Proto.Milvus.CreateCollectionRequest do
  @moduledoc """
  *
  Create collection in milvus
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :schema, 4, type: :bytes
  field :shards_num, 5, type: :int32, json_name: "shardsNum"

  field :consistency_level, 6,
    type: Milvex.Milvus.Proto.Common.ConsistencyLevel,
    json_name: "consistencyLevel",
    enum: true

  field :properties, 7, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
  field :num_partitions, 8, type: :int64, json_name: "numPartitions"
end
