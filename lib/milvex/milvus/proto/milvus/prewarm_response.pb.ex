defmodule Milvex.Milvus.Proto.Milvus.PrewarmResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :taskID, 2, type: :string
  field :namespace, 3, proto3_optional: true, type: :string
end
