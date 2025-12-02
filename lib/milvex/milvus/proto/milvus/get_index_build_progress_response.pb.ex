defmodule Milvex.Milvus.Proto.Milvus.GetIndexBuildProgressResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :indexed_rows, 2, type: :int64, json_name: "indexedRows"
  field :total_rows, 3, type: :int64, json_name: "totalRows"
end
