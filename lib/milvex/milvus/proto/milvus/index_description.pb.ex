defmodule Milvex.Milvus.Proto.Milvus.IndexDescription do
  @moduledoc """
  Index informations
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :index_name, 1, type: :string, json_name: "indexName"
  field :indexID, 2, type: :int64
  field :params, 3, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
  field :field_name, 4, type: :string, json_name: "fieldName"
  field :indexed_rows, 5, type: :int64, json_name: "indexedRows"
  field :total_rows, 6, type: :int64, json_name: "totalRows"
  field :state, 7, type: Milvex.Milvus.Proto.Common.IndexState, enum: true
  field :index_state_fail_reason, 8, type: :string, json_name: "indexStateFailReason"
  field :pending_index_rows, 9, type: :int64, json_name: "pendingIndexRows"
  field :min_index_version, 10, type: :int32, json_name: "minIndexVersion"
  field :max_index_version, 11, type: :int32, json_name: "maxIndexVersion"
end
