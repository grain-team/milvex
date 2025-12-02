defmodule Milvex.Milvus.Proto.Milvus.DescribeIndexRequest do
  @moduledoc """
  Get created index information.
  Current release of Milvus only supports showing latest built index.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :field_name, 4, type: :string, json_name: "fieldName"
  field :index_name, 5, type: :string, json_name: "indexName"
  field :timestamp, 6, type: :uint64
end
