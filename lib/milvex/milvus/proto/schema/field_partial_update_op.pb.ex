defmodule Milvex.Milvus.Proto.Schema.FieldPartialUpdateOp do
  @moduledoc """
  FieldPartialUpdateOp describes how the values carried by the matching
  FieldData should be applied against the existing row during a partial
  upsert.

  The message is referenced from UpsertRequest.field_ops rather than
  embedded in FieldData to keep FieldData a pure data carrier — FieldData
  flows through InsertRequest, QueryResults, SearchResultData and
  internal msgstream paths where an op directive would be meaningless
  and risk accidental echo-back on client-side read-modify-write flows.

  Ops are matched to FieldData entries by field_name. When no op message
  targets a given field, that field is merged with REPLACE semantics
  (full overwrite), preserving backward compatibility.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :field_name, 1, type: :string, json_name: "fieldName"
  field :op, 2, type: Milvex.Milvus.Proto.Schema.FieldPartialUpdateOp.OpType, enum: true
end
