defmodule Milvex.Milvus.Proto.Schema.SearchResultData do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :num_queries, 1, type: :int64, json_name: "numQueries"
  field :top_k, 2, type: :int64, json_name: "topK"

  field :fields_data, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.FieldData,
    json_name: "fieldsData"

  field :scores, 4, repeated: true, type: :float
  field :ids, 5, type: Milvex.Milvus.Proto.Schema.IDs
  field :topks, 6, repeated: true, type: :int64
  field :output_fields, 7, repeated: true, type: :string, json_name: "outputFields"

  field :group_by_field_value, 8,
    type: Milvex.Milvus.Proto.Schema.FieldData,
    json_name: "groupByFieldValue"

  field :all_search_count, 9, type: :int64, json_name: "allSearchCount"
  field :distances, 10, repeated: true, type: :float

  field :search_iterator_v2_results, 11,
    proto3_optional: true,
    type: Milvex.Milvus.Proto.Schema.SearchIteratorV2Results,
    json_name: "searchIteratorV2Results"

  field :recalls, 12, repeated: true, type: :float
  field :primary_field_name, 13, type: :string, json_name: "primaryFieldName"

  field :highlight_results, 14,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.HighlightResult,
    json_name: "highlightResults"

  field :element_indices, 15,
    type: Milvex.Milvus.Proto.Schema.LongArray,
    json_name: "elementIndices"
end
