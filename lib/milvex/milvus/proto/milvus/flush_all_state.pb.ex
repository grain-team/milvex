defmodule Milvex.Milvus.Proto.Milvus.FlushAllState do
  @moduledoc """
  Deprecated
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :db_name, 1, type: :string, json_name: "dbName"

  field :collection_flush_states, 2,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushAllState.CollectionFlushStatesEntry,
    json_name: "collectionFlushStates",
    map: true
end
