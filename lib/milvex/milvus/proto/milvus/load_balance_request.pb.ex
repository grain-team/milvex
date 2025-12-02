defmodule Milvex.Milvus.Proto.Milvus.LoadBalanceRequest do
  @moduledoc """
  Do load balancing operation from src_nodeID to dst_nodeID.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :src_nodeID, 2, type: :int64, json_name: "srcNodeID"
  field :dst_nodeIDs, 3, repeated: true, type: :int64, json_name: "dstNodeIDs"
  field :sealed_segmentIDs, 4, repeated: true, type: :int64, json_name: "sealedSegmentIDs"
  field :collectionName, 5, type: :string
  field :db_name, 6, type: :string, json_name: "dbName"
end
