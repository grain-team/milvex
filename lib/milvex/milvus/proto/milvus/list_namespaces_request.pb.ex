defmodule Milvex.Milvus.Proto.Milvus.ListNamespacesRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :prefix, 4, type: :string
  field :page_size, 5, type: :int64, json_name: "pageSize"
  field :page_token, 6, type: :string, json_name: "pageToken"
end
