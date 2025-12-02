defmodule Milvex.Milvus.Proto.Milvus.HybridSearchRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :partition_names, 4, repeated: true, type: :string, json_name: "partitionNames"
  field :requests, 5, repeated: true, type: Milvex.Milvus.Proto.Milvus.SearchRequest

  field :rank_params, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "rankParams"

  field :travel_timestamp, 7, type: :uint64, json_name: "travelTimestamp"
  field :guarantee_timestamp, 8, type: :uint64, json_name: "guaranteeTimestamp"
  field :not_return_all_meta, 9, type: :bool, json_name: "notReturnAllMeta"
  field :output_fields, 10, repeated: true, type: :string, json_name: "outputFields"

  field :consistency_level, 11,
    type: Milvex.Milvus.Proto.Common.ConsistencyLevel,
    json_name: "consistencyLevel",
    enum: true

  field :use_default_consistency, 12, type: :bool, json_name: "useDefaultConsistency"

  field :function_score, 13,
    type: Milvex.Milvus.Proto.Schema.FunctionScore,
    json_name: "functionScore"

  field :namespace, 14, proto3_optional: true, type: :string
end
