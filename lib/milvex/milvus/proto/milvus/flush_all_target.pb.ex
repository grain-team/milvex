defmodule Milvex.Milvus.Proto.Milvus.FlushAllTarget do
  @moduledoc """
  Deprecated, FlushAll semantics changed to flushing the entire cluster.
  Specific collection to flush with database context
  This message allows targeting specific collections within a database for flush operations
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :db_name, 1, type: :string, json_name: "dbName"
  field :collection_names, 2, repeated: true, type: :string, json_name: "collectionNames"
end
