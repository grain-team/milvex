defmodule Milvex.Milvus.Proto.Milvus.QueryRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :expr, 4, type: :string
  field :output_fields, 5, repeated: true, type: :string, json_name: "outputFields"
  field :partition_names, 6, repeated: true, type: :string, json_name: "partitionNames"
  field :travel_timestamp, 7, type: :uint64, json_name: "travelTimestamp"
  field :guarantee_timestamp, 8, type: :uint64, json_name: "guaranteeTimestamp"

  field :query_params, 9,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "queryParams"

  field :not_return_all_meta, 10, type: :bool, json_name: "notReturnAllMeta"

  field :consistency_level, 11,
    type: Milvex.Milvus.Proto.Common.ConsistencyLevel,
    json_name: "consistencyLevel",
    enum: true

  field :use_default_consistency, 12, type: :bool, json_name: "useDefaultConsistency"

  field :expr_template_values, 13,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.QueryRequest.ExprTemplateValuesEntry,
    json_name: "exprTemplateValues",
    map: true

  field :namespace, 14, proto3_optional: true, type: :string
end
