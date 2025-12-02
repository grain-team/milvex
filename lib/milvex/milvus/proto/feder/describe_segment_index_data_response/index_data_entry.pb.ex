defmodule Milvex.Milvus.Proto.Feder.DescribeSegmentIndexDataResponse.IndexDataEntry do
  use Protobuf, map: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :key, 1, type: :int64
  field :value, 2, type: Milvex.Milvus.Proto.Feder.SegmentIndexData
end
