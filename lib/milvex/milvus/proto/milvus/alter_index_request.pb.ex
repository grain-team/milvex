defmodule Milvex.Milvus.Proto.Milvus.AlterIndexRequest do
  @moduledoc """
  Alter index
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :index_name, 4, type: :string, json_name: "indexName"

  field :extra_params, 5,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "extraParams"

  field :delete_keys, 6, repeated: true, type: :string, json_name: "deleteKeys"
end
