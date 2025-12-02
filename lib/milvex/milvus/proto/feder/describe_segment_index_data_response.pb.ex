defmodule Milvex.Milvus.Proto.Feder.DescribeSegmentIndexDataResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status

  field :index_data, 2,
    repeated: true,
    type: Milvex.Milvus.Proto.Feder.DescribeSegmentIndexDataResponse.IndexDataEntry,
    json_name: "indexData",
    map: true

  field :index_params, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "indexParams"
end
