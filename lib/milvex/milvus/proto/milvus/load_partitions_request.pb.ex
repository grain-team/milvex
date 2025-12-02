defmodule Milvex.Milvus.Proto.Milvus.LoadPartitionsRequest do
  @moduledoc """
  Load specific partitions data of one collection into query nodes
  Then you can get these data as result when you do vector search on this collection.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :partition_names, 4, repeated: true, type: :string, json_name: "partitionNames"
  field :replica_number, 5, type: :int32, json_name: "replicaNumber"
  field :resource_groups, 6, repeated: true, type: :string, json_name: "resourceGroups"
  field :refresh, 7, type: :bool
  field :load_fields, 8, repeated: true, type: :string, json_name: "loadFields"
  field :skip_load_dynamic_field, 9, type: :bool, json_name: "skipLoadDynamicField"

  field :load_params, 10,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.LoadPartitionsRequest.LoadParamsEntry,
    json_name: "loadParams",
    map: true
end
