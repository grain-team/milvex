defmodule Milvex.Milvus.Proto.Milvus.ListAliasesResponse do
  @moduledoc """
  List aliases response
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :aliases, 4, repeated: true, type: :string
end
