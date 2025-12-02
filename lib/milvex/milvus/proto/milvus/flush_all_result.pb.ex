defmodule Milvex.Milvus.Proto.Milvus.FlushAllResult do
  @moduledoc """
  Deprecated
  Flush result for a single flush target
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :db_name, 1, type: :string, json_name: "dbName"

  field :collection_results, 2,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushCollectionResult,
    json_name: "collectionResults"
end
