defmodule Milvex.Milvus.Proto.Milvus.GetStatisticsRequest do
  @moduledoc """
  *
  Get statistics like row_count.
  WARNING: This API is experimental and not useful for now.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :partition_names, 4, repeated: true, type: :string, json_name: "partitionNames"
  field :guarantee_timestamp, 5, type: :uint64, json_name: "guaranteeTimestamp"
end
