defmodule Milvex.Milvus.Proto.Milvus.ReplicaInfo do
  @moduledoc """
  ReplicaGroup
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :replicaID, 1, type: :int64
  field :collectionID, 2, type: :int64
  field :partition_ids, 3, repeated: true, type: :int64, json_name: "partitionIds"

  field :shard_replicas, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.ShardReplica,
    json_name: "shardReplicas"

  field :node_ids, 5, repeated: true, type: :int64, json_name: "nodeIds"
  field :resource_group_name, 6, type: :string, json_name: "resourceGroupName"

  field :num_outbound_node, 7,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.ReplicaInfo.NumOutboundNodeEntry,
    json_name: "numOutboundNode",
    map: true
end
