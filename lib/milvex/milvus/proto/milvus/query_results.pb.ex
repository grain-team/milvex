defmodule Milvex.Milvus.Proto.Milvus.QueryResults do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status

  field :fields_data, 2,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.FieldData,
    json_name: "fieldsData"

  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :output_fields, 4, repeated: true, type: :string, json_name: "outputFields"
  field :session_ts, 5, type: :uint64, json_name: "sessionTs"
  field :primary_field_name, 6, type: :string, json_name: "primaryFieldName"
end
