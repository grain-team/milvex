defmodule Milvex.Milvus.Proto.Milvus.ShowPartitionsRequest do
  @moduledoc """
  List all partitions for particular collection
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :collectionID, 4, type: :int64
  field :partition_names, 5, repeated: true, type: :string, json_name: "partitionNames"
  field :type, 6, type: Milvex.Milvus.Proto.Milvus.ShowType, enum: true, deprecated: true
end
