defmodule Milvex.Milvus.Proto.Milvus.RunAnalyzerRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :analyzer_params, 2, type: :string, json_name: "analyzerParams"
  field :placeholder, 3, repeated: true, type: :bytes
  field :with_detail, 4, type: :bool, json_name: "withDetail"
  field :with_hash, 5, type: :bool, json_name: "withHash"
  field :db_name, 6, type: :string, json_name: "dbName"
  field :collection_name, 7, type: :string, json_name: "collectionName"
  field :field_name, 8, type: :string, json_name: "fieldName"
  field :analyzer_names, 9, repeated: true, type: :string, json_name: "analyzerNames"
end
