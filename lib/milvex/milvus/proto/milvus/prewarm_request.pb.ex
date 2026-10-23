defmodule Milvex.Milvus.Proto.Milvus.PrewarmRequest do
  @moduledoc """
  Prewarm namespace partition data into query node memory/cache.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :namespace, 4, proto3_optional: true, type: :string
  field :replica_number, 5, type: :int32, json_name: "replicaNumber"
  field :resource_groups, 6, repeated: true, type: :string, json_name: "resourceGroups"
  field :load_fields, 7, repeated: true, type: :string, json_name: "loadFields"
  field :skip_load_dynamic_field, 8, type: :bool, json_name: "skipLoadDynamicField"

  field :load_params, 9,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.PrewarmRequest.LoadParamsEntry,
    json_name: "loadParams",
    map: true

  field :ttl_seconds, 10, type: :int64, json_name: "ttlSeconds"
  field :priority, 11, type: :string
end
