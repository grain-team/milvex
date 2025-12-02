defmodule Milvex.Milvus.Proto.Milvus.GetIndexBuildProgressRequest do
  @moduledoc """
  Get index building progress
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :field_name, 4, type: :string, json_name: "fieldName"
  field :index_name, 5, type: :string, json_name: "indexName"
end
