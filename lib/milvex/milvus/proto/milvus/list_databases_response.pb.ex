defmodule Milvex.Milvus.Proto.Milvus.ListDatabasesResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :db_names, 2, repeated: true, type: :string, json_name: "dbNames"
  field :created_timestamp, 3, repeated: true, type: :uint64, json_name: "createdTimestamp"
  field :db_ids, 4, repeated: true, type: :int64, json_name: "dbIds"
end
