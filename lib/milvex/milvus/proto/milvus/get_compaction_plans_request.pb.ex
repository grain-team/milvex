defmodule Milvex.Milvus.Proto.Milvus.GetCompactionPlansRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :compactionID, 1, type: :int64
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :collection_id, 4, type: :int64, json_name: "collectionId"
end
