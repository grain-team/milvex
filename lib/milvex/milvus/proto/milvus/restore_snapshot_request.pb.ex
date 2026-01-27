defmodule Milvex.Milvus.Proto.Milvus.RestoreSnapshotRequest do
  @moduledoc """
  restore a snapshot to a new collection
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :name, 2, type: :string
  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :rewrite_data, 5, type: :bool, json_name: "rewriteData"
end
