defmodule Milvex.Milvus.Proto.Milvus.ReleasePartitionsRequest do
  @moduledoc """
  Release specific partitions data of one collection from query nodes.
  Then you can not get these data as result when you do vector search on this collection.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :partition_names, 4, repeated: true, type: :string, json_name: "partitionNames"
end
