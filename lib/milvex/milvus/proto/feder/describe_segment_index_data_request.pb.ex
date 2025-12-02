defmodule Milvex.Milvus.Proto.Feder.DescribeSegmentIndexDataRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :collection_name, 2, type: :string, json_name: "collectionName"
  field :index_name, 3, type: :string, json_name: "indexName"
  field :segmentsIDs, 4, repeated: true, type: :int64
end
