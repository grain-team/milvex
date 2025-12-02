defmodule Milvex.Milvus.Proto.Milvus.ComputePhraseMatchSlopRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :analyzer_params, 2, type: :string, json_name: "analyzerParams"
  field :query_text, 3, type: :string, json_name: "queryText"
  field :data_texts, 4, repeated: true, type: :string, json_name: "dataTexts"
end
