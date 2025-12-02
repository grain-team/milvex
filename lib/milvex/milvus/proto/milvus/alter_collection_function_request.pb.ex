defmodule Milvex.Milvus.Proto.Milvus.AlterCollectionFunctionRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :collectionID, 4, type: :int64
  field :function_name, 5, type: :string, json_name: "functionName"
  field :functionSchema, 6, type: Milvex.Milvus.Proto.Schema.FunctionSchema
end
