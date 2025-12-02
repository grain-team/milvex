defmodule Milvex.Milvus.Proto.Milvus.CalcDistanceRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :op_left, 2, type: Milvex.Milvus.Proto.Milvus.VectorsArray, json_name: "opLeft"
  field :op_right, 3, type: Milvex.Milvus.Proto.Milvus.VectorsArray, json_name: "opRight"
  field :params, 4, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
end
