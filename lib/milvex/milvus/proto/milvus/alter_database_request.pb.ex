defmodule Milvex.Milvus.Proto.Milvus.AlterDatabaseRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :db_id, 3, type: :string, json_name: "dbId"
  field :properties, 4, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
  field :delete_keys, 5, repeated: true, type: :string, json_name: "deleteKeys"
end
