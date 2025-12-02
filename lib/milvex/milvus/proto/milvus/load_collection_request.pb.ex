defmodule Milvex.Milvus.Proto.Milvus.LoadCollectionRequest do
  @moduledoc """
  *
  Load collection data into query nodes, then you can do vector search on this collection.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :replica_number, 4, type: :int32, json_name: "replicaNumber"
  field :resource_groups, 5, repeated: true, type: :string, json_name: "resourceGroups"
  field :refresh, 6, type: :bool
  field :load_fields, 7, repeated: true, type: :string, json_name: "loadFields"
  field :skip_load_dynamic_field, 8, type: :bool, json_name: "skipLoadDynamicField"

  field :load_params, 9,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.LoadCollectionRequest.LoadParamsEntry,
    json_name: "loadParams",
    map: true
end
