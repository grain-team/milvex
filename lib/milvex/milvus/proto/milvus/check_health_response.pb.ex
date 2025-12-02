defmodule Milvex.Milvus.Proto.Milvus.CheckHealthResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :isHealthy, 2, type: :bool
  field :reasons, 3, repeated: true, type: :string

  field :quota_states, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.QuotaState,
    json_name: "quotaStates",
    enum: true
end
