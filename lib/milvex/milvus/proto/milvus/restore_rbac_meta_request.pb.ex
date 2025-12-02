defmodule Milvex.Milvus.Proto.Milvus.RestoreRBACMetaRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :RBAC_meta, 2, type: Milvex.Milvus.Proto.Milvus.RBACMeta, json_name: "RBACMeta"
end
