defmodule Milvex.Application do
  @moduledoc false
  use Application

  @doc false
  def start(_type, _args) do
    children =
      [
        GRPC.Client.Supervisor
      ] ++ dev_children()

    opts = [strategy: :one_for_one, name: Milvex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dev_children do
    if System.get_env("TIDEWAVE_REPL") == "true" and Code.ensure_loaded?(Bandit) do
      ensure_tidewave_started()
      port = String.to_integer(System.get_env("TIDEWAVE_PORT", "10001"))
      [{Bandit, plug: Tidewave, port: port}]
    else
      []
    end
  end

  defp ensure_tidewave_started do
    case Application.ensure_all_started(:tidewave) do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end
  end
end
