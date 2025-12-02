defmodule Milvex.Milvus.Proto.Milvus.GetPartitionStatisticsRequest do
  @moduledoc """
  Get partition statistics like row_count.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :partition_name, 4, type: :string, json_name: "partitionName"
end
