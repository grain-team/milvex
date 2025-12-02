defmodule Milvex.Milvus.Proto.Milvus.GetImportStateResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :state, 2, type: Milvex.Milvus.Proto.Common.ImportState, enum: true
  field :row_count, 3, type: :int64, json_name: "rowCount"
  field :id_list, 4, repeated: true, type: :int64, json_name: "idList"
  field :infos, 5, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
  field :id, 6, type: :int64
  field :collection_id, 7, type: :int64, json_name: "collectionId"
  field :segment_ids, 8, repeated: true, type: :int64, json_name: "segmentIds"
  field :create_ts, 9, type: :int64, json_name: "createTs"
end
