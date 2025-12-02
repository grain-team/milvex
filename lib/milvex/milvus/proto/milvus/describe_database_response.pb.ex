defmodule Milvex.Milvus.Proto.Milvus.DescribeDatabaseResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :db_name, 2, type: :string, json_name: "dbName"
  field :dbID, 3, type: :int64
  field :created_timestamp, 4, type: :uint64, json_name: "createdTimestamp"
  field :properties, 5, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
end
