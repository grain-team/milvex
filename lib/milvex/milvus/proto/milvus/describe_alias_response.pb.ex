defmodule Milvex.Milvus.Proto.Milvus.DescribeAliasResponse do
  @moduledoc """
  Describe alias response
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :db_name, 2, type: :string, json_name: "dbName"
  field :alias, 3, type: :string
  field :collection, 4, type: :string
end
