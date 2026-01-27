defmodule Milvex.Milvus.Proto.Milvus.DescribeSnapshotResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :name, 2, type: :string
  field :description, 3, type: :string
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :partition_names, 5, repeated: true, type: :string, json_name: "partitionNames"
  field :create_ts, 6, type: :int64, json_name: "createTs"
  field :s3_location, 7, type: :string, json_name: "s3Location"
end
