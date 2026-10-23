defmodule Milvex.Milvus.Proto.Milvus.ExportSnapshotRequest do
  @moduledoc """
  export a snapshot and all referenced files to a self-contained external bundle
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :name, 2, type: :string
  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :target_s3_path, 5, type: :string, json_name: "targetS3Path"
  field :external_spec, 6, type: :string, json_name: "externalSpec"
end
