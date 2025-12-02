defmodule Milvex.Milvus.Proto.Milvus.AlterCollectionRequest do
  @moduledoc """
  *
  Alter collection in milvus
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :collectionID, 4, type: :int64
  field :properties, 5, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
  field :delete_keys, 6, repeated: true, type: :string, json_name: "deleteKeys"
end
