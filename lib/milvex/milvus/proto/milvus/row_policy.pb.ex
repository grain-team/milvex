defmodule Milvex.Milvus.Proto.Milvus.RowPolicy do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :policy_name, 1, type: :string, json_name: "policyName"
  field :actions, 2, repeated: true, type: Milvex.Milvus.Proto.Milvus.RowPolicyAction, enum: true
  field :roles, 3, repeated: true, type: :string
  field :using_expr, 4, type: :string, json_name: "usingExpr"
  field :check_expr, 5, type: :string, json_name: "checkExpr"
  field :description, 6, type: :string
  field :created_at, 7, type: :int64, json_name: "createdAt"
end
