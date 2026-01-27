defmodule Milvex.Milvus.Proto.Common.Metrics do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :request_count, 1, type: :int64, json_name: "requestCount"
  field :success_count, 2, type: :int64, json_name: "successCount"
  field :error_count, 3, type: :int64, json_name: "errorCount"
  field :avg_latency_ms, 4, type: :double, json_name: "avgLatencyMs"
  field :p99_latency_ms, 5, type: :double, json_name: "p99LatencyMs"
  field :max_latency_ms, 6, type: :double, json_name: "maxLatencyMs"
end
