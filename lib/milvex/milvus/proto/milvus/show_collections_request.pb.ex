defmodule Milvex.Milvus.Proto.Milvus.ShowCollectionsRequest do
  @moduledoc """
  List collections
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :time_stamp, 3, type: :uint64, json_name: "timeStamp"
  field :type, 4, type: Milvex.Milvus.Proto.Milvus.ShowType, enum: true

  field :collection_names, 5,
    repeated: true,
    type: :string,
    json_name: "collectionNames",
    deprecated: true
end
