defmodule Milvex.Milvus.Proto.Milvus.GetClientTelemetryRequest do
  @moduledoc """
  Get Client Telemetry
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :database, 1, type: :string
  field :client_id, 2, type: :string, json_name: "clientId"
  field :include_metrics, 3, type: :bool, json_name: "includeMetrics"
end
