defmodule Milvex.Milvus.Proto.Msg.CreateCollectionRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collectionName, 3, type: :string
  field :partitionName, 4, type: :string
  field :dbID, 5, type: :int64
  field :collectionID, 6, type: :int64
  field :partitionID, 7, type: :int64, deprecated: true
  field :schema, 8, type: :bytes, deprecated: true
  field :virtualChannelNames, 9, repeated: true, type: :string
  field :physicalChannelNames, 10, repeated: true, type: :string
  field :partitionIDs, 11, repeated: true, type: :int64
  field :partitionNames, 12, repeated: true, type: :string

  field :collection_schema, 13,
    type: Milvex.Milvus.Proto.Schema.CollectionSchema,
    json_name: "collectionSchema"
end
