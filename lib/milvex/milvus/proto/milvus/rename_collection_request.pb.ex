defmodule Milvex.Milvus.Proto.Milvus.RenameCollectionRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :oldName, 3, type: :string
  field :newName, 4, type: :string
  field :newDBName, 5, type: :string
end
