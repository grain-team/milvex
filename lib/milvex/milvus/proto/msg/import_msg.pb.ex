defmodule Milvex.Milvus.Proto.Msg.ImportMsg do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :collectionID, 4, type: :int64
  field :partitionIDs, 5, repeated: true, type: :int64

  field :options, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Msg.ImportMsg.OptionsEntry,
    map: true

  field :files, 7, repeated: true, type: Milvex.Milvus.Proto.Msg.ImportFile
  field :schema, 8, type: Milvex.Milvus.Proto.Schema.CollectionSchema
  field :jobID, 9, type: :int64
end
