defmodule Milvex.Milvus.Proto.Milvus.DeleteRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :partition_name, 4, type: :string, json_name: "partitionName"
  field :expr, 5, type: :string
  field :hash_keys, 6, repeated: true, type: :uint32, json_name: "hashKeys"

  field :consistency_level, 7,
    type: Milvex.Milvus.Proto.Common.ConsistencyLevel,
    json_name: "consistencyLevel",
    enum: true

  field :expr_template_values, 8,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.DeleteRequest.ExprTemplateValuesEntry,
    json_name: "exprTemplateValues",
    map: true
end
