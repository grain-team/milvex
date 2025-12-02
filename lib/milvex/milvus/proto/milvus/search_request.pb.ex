defmodule Milvex.Milvus.Proto.Milvus.SearchRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :search_input, 0

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :partition_names, 4, repeated: true, type: :string, json_name: "partitionNames"
  field :dsl, 5, type: :string
  field :placeholder_group, 6, type: :bytes, json_name: "placeholderGroup", oneof: 0
  field :ids, 22, type: Milvex.Milvus.Proto.Schema.IDs, oneof: 0
  field :dsl_type, 7, type: Milvex.Milvus.Proto.Common.DslType, json_name: "dslType", enum: true
  field :output_fields, 8, repeated: true, type: :string, json_name: "outputFields"

  field :search_params, 9,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "searchParams"

  field :travel_timestamp, 10, type: :uint64, json_name: "travelTimestamp"
  field :guarantee_timestamp, 11, type: :uint64, json_name: "guaranteeTimestamp"
  field :nq, 12, type: :int64
  field :not_return_all_meta, 13, type: :bool, json_name: "notReturnAllMeta"

  field :consistency_level, 14,
    type: Milvex.Milvus.Proto.Common.ConsistencyLevel,
    json_name: "consistencyLevel",
    enum: true

  field :use_default_consistency, 15, type: :bool, json_name: "useDefaultConsistency"

  field :search_by_primary_keys, 16,
    type: :bool,
    json_name: "searchByPrimaryKeys",
    deprecated: true

  field :sub_reqs, 17,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.SubSearchRequest,
    json_name: "subReqs"

  field :expr_template_values, 18,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.SearchRequest.ExprTemplateValuesEntry,
    json_name: "exprTemplateValues",
    map: true

  field :function_score, 19,
    type: Milvex.Milvus.Proto.Schema.FunctionScore,
    json_name: "functionScore"

  field :namespace, 20, proto3_optional: true, type: :string
  field :highlighter, 21, type: Milvex.Milvus.Proto.Common.Highlighter
end
