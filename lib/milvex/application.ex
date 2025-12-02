defmodule Milvex.Application do
  use Application

  def start(_type, _args) do
    children = [
      GRPC.Client.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Milvex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
