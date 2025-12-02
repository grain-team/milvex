defmodule Milvex.Milvus.Proto.Milvus.ReplicateRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :request, 0

  field :replicate_message, 1,
    type: Milvex.Milvus.Proto.Milvus.ReplicateMessage,
    json_name: "replicateMessage",
    oneof: 0
end
