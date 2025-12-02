defmodule Milvex.Milvus.Proto.Milvus.GetLoadStateRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :collection_name, 2, type: :string, json_name: "collectionName"
  field :partition_names, 3, repeated: true, type: :string, json_name: "partitionNames"
  field :db_name, 4, type: :string, json_name: "dbName"
end
