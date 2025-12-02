defmodule Milvex.Milvus.Proto.Milvus.GetFlushAllStateResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :flushed, 2, type: :bool

  field :flush_states, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushAllState,
    json_name: "flushStates",
    deprecated: true
end
