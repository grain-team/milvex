defmodule Milvex.Milvus.Proto.Milvus.DescribeCollectionRequest do
  @moduledoc """
  *
  Get collection meta datas like: schema, collectionID, shards number ...
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :collectionID, 4, type: :int64
  field :time_stamp, 5, type: :uint64, json_name: "timeStamp"
end
