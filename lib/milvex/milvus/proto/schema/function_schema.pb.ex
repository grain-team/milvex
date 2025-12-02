defmodule Milvex.Milvus.Proto.Schema.FunctionSchema do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :name, 1, type: :string
  field :id, 2, type: :int64
  field :description, 3, type: :string
  field :type, 4, type: Milvex.Milvus.Proto.Schema.FunctionType, enum: true
  field :input_field_names, 5, repeated: true, type: :string, json_name: "inputFieldNames"
  field :input_field_ids, 6, repeated: true, type: :int64, json_name: "inputFieldIds"
  field :output_field_names, 7, repeated: true, type: :string, json_name: "outputFieldNames"
  field :output_field_ids, 8, repeated: true, type: :int64, json_name: "outputFieldIds"
  field :params, 9, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
end
