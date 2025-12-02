defmodule Milvex.Milvus.Proto.Milvus.GetLoadingProgressResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :progress, 2, type: :int64
  field :refresh_progress, 3, type: :int64, json_name: "refreshProgress"
end
