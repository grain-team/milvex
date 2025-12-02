defmodule Milvex.Milvus.Proto.Milvus.ResourceGroup do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :name, 1, type: :string
  field :capacity, 2, type: :int32
  field :num_available_node, 3, type: :int32, json_name: "numAvailableNode"

  field :num_loaded_replica, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.ResourceGroup.NumLoadedReplicaEntry,
    json_name: "numLoadedReplica",
    map: true

  field :num_outgoing_node, 5,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.ResourceGroup.NumOutgoingNodeEntry,
    json_name: "numOutgoingNode",
    map: true

  field :num_incoming_node, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.ResourceGroup.NumIncomingNodeEntry,
    json_name: "numIncomingNode",
    map: true

  field :config, 7, type: Milvex.Milvus.Proto.Rg.ResourceGroupConfig
  field :nodes, 8, repeated: true, type: Milvex.Milvus.Proto.Common.NodeInfo
end
