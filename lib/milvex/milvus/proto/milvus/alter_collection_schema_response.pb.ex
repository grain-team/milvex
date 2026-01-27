defmodule Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :alter_status, 1, type: Milvex.Milvus.Proto.Common.Status, json_name: "alterStatus"
  field :index_status, 2, type: Milvex.Milvus.Proto.Common.Status, json_name: "indexStatus"
end
