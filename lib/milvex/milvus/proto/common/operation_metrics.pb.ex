defmodule Milvex.Milvus.Proto.Common.OperationMetrics do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :operation, 1, type: :string
  field :global, 2, type: Milvex.Milvus.Proto.Common.Metrics

  field :collection_metrics, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.OperationMetrics.CollectionMetricsEntry,
    json_name: "collectionMetrics",
    map: true
end
