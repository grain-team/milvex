defmodule Milvex.Milvus.Proto.Milvus.ReplicateResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :response, 0

  field :replicate_confirmed_message_info, 1,
    type: Milvex.Milvus.Proto.Milvus.ReplicateConfirmedMessageInfo,
    json_name: "replicateConfirmedMessageInfo",
    oneof: 0
end
