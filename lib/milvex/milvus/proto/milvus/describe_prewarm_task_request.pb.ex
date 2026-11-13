defmodule Milvex.Milvus.Proto.Milvus.DescribePrewarmTaskRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :taskID, 2, type: :string
end
