defmodule Milvex.Milvus.Proto.Milvus.GetIndexStatisticsRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :index_name, 4, type: :string, json_name: "indexName"
  field :timestamp, 5, type: :uint64
end
