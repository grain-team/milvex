defmodule Milvex.MixProject do
  use Mix.Project

  def project do
    [
      app: :milvex,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:grpc, "~> 0.11.5"},
      {:protobuf, "~> 0.15.0"}
    ]
  end
end
