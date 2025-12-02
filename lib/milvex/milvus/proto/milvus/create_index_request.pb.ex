defmodule Milvex.Milvus.Proto.Milvus.CreateIndexRequest do
  @moduledoc """
  Create index for vector datas
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :field_name, 4, type: :string, json_name: "fieldName"

  field :extra_params, 5,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "extraParams"

  field :index_name, 6, type: :string, json_name: "indexName"
end
