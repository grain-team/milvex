defmodule Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaRequest.DropRequest do
  @moduledoc """
  Drop field request
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :field_identifier, 0

  field :field_name, 1, type: :string, json_name: "fieldName", oneof: 0
  field :field_id, 2, type: :int64, json_name: "fieldId", oneof: 0
end
