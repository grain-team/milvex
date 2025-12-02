defmodule Milvex.Milvus.Proto.Milvus.MutationResult do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :IDs, 2, type: Milvex.Milvus.Proto.Schema.IDs
  field :succ_index, 3, repeated: true, type: :uint32, json_name: "succIndex"
  field :err_index, 4, repeated: true, type: :uint32, json_name: "errIndex"
  field :acknowledged, 5, type: :bool
  field :insert_cnt, 6, type: :int64, json_name: "insertCnt"
  field :delete_cnt, 7, type: :int64, json_name: "deleteCnt"
  field :upsert_cnt, 8, type: :int64, json_name: "upsertCnt"
  field :timestamp, 9, type: :uint64
end
