defmodule Milvex.Milvus.Proto.Schema.AggBucket do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :key, 1, repeated: true, type: Milvex.Milvus.Proto.Schema.BucketKeyEntry
  field :count, 2, type: :int64

  field :metrics, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.AggBucket.MetricsEntry,
    map: true

  field :hits, 4, repeated: true, type: Milvex.Milvus.Proto.Schema.AggHit

  field :sub_groups, 5,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.AggBucket,
    json_name: "subGroups"
end
