defmodule Milvex.Milvus.Proto.Milvus.FlushRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_names, 3, repeated: true, type: :string, json_name: "collectionNames"
end
