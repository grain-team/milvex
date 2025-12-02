defmodule Milvex.Milvus.Proto.Milvus.GetLoadStateResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :state, 2, type: Milvex.Milvus.Proto.Common.LoadState, enum: true
end
