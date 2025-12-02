defmodule Milvex.Milvus.Proto.Msg.DeleteRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :shardName, 2, type: :string
  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :partition_name, 5, type: :string, json_name: "partitionName"
  field :dbID, 6, type: :int64
  field :collectionID, 7, type: :int64
  field :partitionID, 8, type: :int64
  field :int64_primary_keys, 9, repeated: true, type: :int64, json_name: "int64PrimaryKeys"
  field :timestamps, 10, repeated: true, type: :uint64
  field :num_rows, 11, type: :int64, json_name: "numRows"
  field :primary_keys, 12, type: Milvex.Milvus.Proto.Schema.IDs, json_name: "primaryKeys"
  field :segment_id, 13, type: :int64, json_name: "segmentId"
end
