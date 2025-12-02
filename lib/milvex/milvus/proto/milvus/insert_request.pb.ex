defmodule Milvex.Milvus.Proto.Milvus.InsertRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :partition_name, 4, type: :string, json_name: "partitionName"

  field :fields_data, 5,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.FieldData,
    json_name: "fieldsData"

  field :hash_keys, 6, repeated: true, type: :uint32, json_name: "hashKeys"
  field :num_rows, 7, type: :uint32, json_name: "numRows"
  field :schema_timestamp, 8, type: :uint64, json_name: "schemaTimestamp"
  field :namespace, 9, proto3_optional: true, type: :string
end
