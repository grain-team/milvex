defmodule Milvex.Milvus.Proto.Milvus.UpdateRowPolicyRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :policy_name, 4, type: :string, json_name: "policyName"
  field :actions, 5, repeated: true, type: Milvex.Milvus.Proto.Milvus.RowPolicyAction, enum: true
  field :roles, 6, repeated: true, type: :string, deprecated: true
  field :using_expr, 7, type: :string, json_name: "usingExpr"
  field :check_expr, 8, type: :string, json_name: "checkExpr"
  field :description, 9, type: :string

  field :policy_type, 10,
    type: Milvex.Milvus.Proto.Milvus.RowPolicyType,
    json_name: "policyType",
    enum: true
end
