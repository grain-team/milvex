defmodule Milvex.Milvus.Proto.Feder.SegmentIndexData do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :segmentID, 1, type: :int64
  field :index_data, 2, type: :string, json_name: "indexData"
end
