defmodule Milvex.Milvus.Proto.Milvus.DescribePrewarmTaskResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :taskID, 2, type: :string
  field :state, 3, type: Milvex.Milvus.Proto.Milvus.PrewarmTaskState, enum: true
  field :progress, 4, type: :int32
  field :error_message, 5, type: :string, json_name: "errorMessage"
end
