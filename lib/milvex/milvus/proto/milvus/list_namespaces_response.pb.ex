defmodule Milvex.Milvus.Proto.Milvus.ListNamespacesResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :namespaces, 2, repeated: true, type: Milvex.Milvus.Proto.Milvus.NamespaceInfo
  field :next_page_token, 3, type: :string, json_name: "nextPageToken"
end
