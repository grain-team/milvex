defmodule Milvex.Milvus.Proto.Milvus.BackupRBACMetaResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :RBAC_meta, 2, type: Milvex.Milvus.Proto.Milvus.RBACMeta, json_name: "RBACMeta"
end
