defmodule Milvex.Milvus.Proto.Msg.DropCollectionRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collectionName, 3, type: :string
  field :dbID, 4, type: :int64
  field :collectionID, 5, type: :int64
end
