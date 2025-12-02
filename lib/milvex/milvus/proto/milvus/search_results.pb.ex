defmodule Milvex.Milvus.Proto.Milvus.SearchResults do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :results, 2, type: Milvex.Milvus.Proto.Schema.SearchResultData
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :session_ts, 4, type: :uint64, json_name: "sessionTs"
end
