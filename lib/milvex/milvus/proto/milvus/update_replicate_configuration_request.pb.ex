defmodule Milvex.Milvus.Proto.Milvus.UpdateReplicateConfigurationRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :replicate_configuration, 1,
    type: Milvex.Milvus.Proto.Common.ReplicateConfiguration,
    json_name: "replicateConfiguration"
end
