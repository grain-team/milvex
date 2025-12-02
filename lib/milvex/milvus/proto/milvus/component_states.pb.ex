defmodule Milvex.Milvus.Proto.Milvus.ComponentStates do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :state, 1, type: Milvex.Milvus.Proto.Milvus.ComponentInfo

  field :subcomponent_states, 2,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.ComponentInfo,
    json_name: "subcomponentStates"

  field :status, 3, type: Milvex.Milvus.Proto.Common.Status
end
