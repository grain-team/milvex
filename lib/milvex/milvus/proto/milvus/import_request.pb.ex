defmodule Milvex.Milvus.Proto.Milvus.ImportRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :collection_name, 1, type: :string, json_name: "collectionName"
  field :partition_name, 2, type: :string, json_name: "partitionName"
  field :channel_names, 3, repeated: true, type: :string, json_name: "channelNames"
  field :row_based, 4, type: :bool, json_name: "rowBased"
  field :files, 5, repeated: true, type: :string
  field :options, 6, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
  field :db_name, 7, type: :string, json_name: "dbName"
  field :clustering_info, 8, type: :bytes, json_name: "clusteringInfo"
end
