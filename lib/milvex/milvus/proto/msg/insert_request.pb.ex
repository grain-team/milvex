defmodule Milvex.Milvus.Proto.Msg.InsertRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :shardName, 2, type: :string
  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :partition_name, 5, type: :string, json_name: "partitionName"
  field :dbID, 6, type: :int64
  field :collectionID, 7, type: :int64
  field :partitionID, 8, type: :int64
  field :segmentID, 9, type: :int64
  field :timestamps, 10, repeated: true, type: :uint64
  field :rowIDs, 11, repeated: true, type: :int64
  field :row_data, 12, repeated: true, type: Milvex.Milvus.Proto.Common.Blob, json_name: "rowData"

  field :fields_data, 13,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.FieldData,
    json_name: "fieldsData"

  field :num_rows, 14, type: :uint64, json_name: "numRows"
  field :version, 15, type: Milvex.Milvus.Proto.Msg.InsertDataVersion, enum: true
  field :namespace, 16, proto3_optional: true, type: :string
end
