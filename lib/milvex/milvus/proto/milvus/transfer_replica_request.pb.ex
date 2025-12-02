defmodule Milvex.Milvus.Proto.Milvus.TransferReplicaRequest do
  @moduledoc """
  transfer `replicaNum` replicas in `collectionID` from `source_resource_group` to `target_resource_group`
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :source_resource_group, 2, type: :string, json_name: "sourceResourceGroup"
  field :target_resource_group, 3, type: :string, json_name: "targetResourceGroup"
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :num_replica, 5, type: :int64, json_name: "numReplica"
  field :db_name, 6, type: :string, json_name: "dbName"
end
