defmodule Milvex.Milvus.Proto.Milvus.NamespaceStats do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :stats, 1, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
  field :approx_entity_count, 2, type: :int64, json_name: "approxEntityCount"
  field :entity_count, 3, type: :int64, json_name: "entityCount"
  field :entity_count_type, 4, type: :string, json_name: "entityCountType"
  field :logical_bytes, 5, type: :int64, json_name: "logicalBytes"
  field :last_write_timestamp, 6, type: :uint64, json_name: "lastWriteTimestamp"
  field :last_write_utc_timestamp, 7, type: :uint64, json_name: "lastWriteUtcTimestamp"
end
