defmodule Milvex.Milvus.Proto.Milvus.ClusterInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :cluster_id, 1, type: :string, json_name: "clusterId"
  field :cchannel, 2, type: :string
  field :pchannels, 3, repeated: true, type: :string
end
