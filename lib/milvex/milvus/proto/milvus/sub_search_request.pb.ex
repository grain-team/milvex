defmodule Milvex.Milvus.Proto.Milvus.SubSearchRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :dsl, 1, type: :string
  field :placeholder_group, 2, type: :bytes, json_name: "placeholderGroup"
  field :dsl_type, 3, type: Milvex.Milvus.Proto.Common.DslType, json_name: "dslType", enum: true

  field :search_params, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "searchParams"

  field :nq, 5, type: :int64

  field :expr_template_values, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.SubSearchRequest.ExprTemplateValuesEntry,
    json_name: "exprTemplateValues",
    map: true

  field :namespace, 7, proto3_optional: true, type: :string
end
