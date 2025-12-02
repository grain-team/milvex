defmodule Milvex.Milvus.Proto.Milvus.GetReplicateInfoRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :source_cluster_id, 1, type: :string, json_name: "sourceClusterId"
  field :target_pchannel, 2, type: :string, json_name: "targetPchannel"
end
