defmodule Milvex.Milvus.Proto.Milvus.GetClientTelemetryResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :clients, 2, repeated: true, type: Milvex.Milvus.Proto.Milvus.ClientTelemetry
  field :aggregated, 3, type: Milvex.Milvus.Proto.Common.Metrics
end
