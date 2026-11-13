defmodule Milvex.Milvus.Proto.Milvus.RestoreExternalSnapshotRequest do
  @moduledoc """
  restore an external snapshot by metadata URI to a new collection
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :target_collection_name, 3, type: :string, json_name: "targetCollectionName"
  field :snapshot_metadata_uri, 4, type: :string, json_name: "snapshotMetadataUri"
  field :external_spec, 5, type: :string, json_name: "externalSpec"
end
