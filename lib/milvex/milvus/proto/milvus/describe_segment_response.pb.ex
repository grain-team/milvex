defmodule Milvex.Milvus.Proto.Milvus.DescribeSegmentResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :indexID, 2, type: :int64
  field :buildID, 3, type: :int64
  field :enable_index, 4, type: :bool, json_name: "enableIndex"
  field :fieldID, 5, type: :int64
end
