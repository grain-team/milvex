defmodule Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaRequest.AddRequest do
  @moduledoc """
  Add fields and functions request
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :field_infos, 1,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaRequest.FieldInfo,
    json_name: "fieldInfos"

  field :func_schema, 2,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.FunctionSchema,
    json_name: "funcSchema"

  field :do_physical_backfill, 3, type: :bool, json_name: "doPhysicalBackfill"
end
