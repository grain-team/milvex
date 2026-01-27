defmodule Milvex.Milvus.Proto.Milvus.CreateSnapshotRequest do
  @moduledoc """
  Snapshot Management
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :name, 2, type: :string
  field :description, 3, type: :string
  field :db_name, 4, type: :string, json_name: "dbName"
  field :collection_name, 5, type: :string, json_name: "collectionName"
end
