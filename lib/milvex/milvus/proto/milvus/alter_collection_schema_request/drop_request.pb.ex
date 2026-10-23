defmodule Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaRequest.DropRequest do
  @moduledoc """
  Drop field or function request
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :identifier, 0

  field :field_name, 1, type: :string, json_name: "fieldName", oneof: 0
  field :field_id, 2, type: :int64, json_name: "fieldId", oneof: 0
  field :function_name, 3, type: :string, json_name: "functionName", oneof: 0
  field :drop_function_output_fields, 4, type: :bool, json_name: "dropFunctionOutputFields"
end
