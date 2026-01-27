defmodule Milvex.Milvus.Proto.Milvus.ClientTelemetryService.Service do
  @moduledoc """
  Client Telemetry Service
  """

  use GRPC.Service,
    name: "milvus.proto.milvus.ClientTelemetryService",
    protoc_gen_elixir_version: "0.15.0"

  rpc :ClientHeartbeat,
      Milvex.Milvus.Proto.Milvus.ClientHeartbeatRequest,
      Milvex.Milvus.Proto.Milvus.ClientHeartbeatResponse

  rpc :GetClientTelemetry,
      Milvex.Milvus.Proto.Milvus.GetClientTelemetryRequest,
      Milvex.Milvus.Proto.Milvus.GetClientTelemetryResponse

  rpc :PushClientCommand,
      Milvex.Milvus.Proto.Milvus.PushClientCommandRequest,
      Milvex.Milvus.Proto.Milvus.PushClientCommandResponse

  rpc :DeleteClientCommand,
      Milvex.Milvus.Proto.Milvus.DeleteClientCommandRequest,
      Milvex.Milvus.Proto.Milvus.DeleteClientCommandResponse
end

defmodule Milvex.Milvus.Proto.Milvus.ClientTelemetryService.Stub do
  use GRPC.Stub, service: Milvex.Milvus.Proto.Milvus.ClientTelemetryService.Service
end
