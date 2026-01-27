defmodule Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaRequest.FieldInfo do
  @moduledoc """
  The serialized `schema.FieldSchema`
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :field_schema, 1, type: Milvex.Milvus.Proto.Schema.FieldSchema, json_name: "fieldSchema"
  field :index_name, 2, type: :string, json_name: "indexName"

  field :extra_params, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "extraParams"
end
