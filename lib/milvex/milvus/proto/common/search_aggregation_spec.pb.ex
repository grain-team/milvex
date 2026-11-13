defmodule Milvex.Milvus.Proto.Common.SearchAggregationSpec do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :fields, 1, repeated: true, type: :string
  field :size, 2, type: :int64

  field :metrics, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.SearchAggregationSpec.MetricsEntry,
    map: true

  field :order, 4, repeated: true, type: Milvex.Milvus.Proto.Common.OrderSpec
  field :top_hits, 5, type: Milvex.Milvus.Proto.Common.TopHitsSpec, json_name: "topHits"

  field :sub_aggregation, 6,
    type: Milvex.Milvus.Proto.Common.SearchAggregationSpec,
    json_name: "subAggregation"

  field :search_size, 7, type: :int64, json_name: "searchSize"
end
