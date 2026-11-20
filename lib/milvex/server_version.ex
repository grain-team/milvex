defmodule Milvex.ServerVersion do
  @moduledoc """
  Lazy server version detection, remembered per established channel.

  The version is detected on first use and handed to the connection that owns
  the channel, which returns it in the config from
  `Milvex.Connection.get_channel/2` until that channel is replaced.

  Groups B to F must call `require/4` before sending a 3.0-only field or RPC,
  for example `require(conn, ">= 3.0.0", "feature", opts)`. Unknown versions
  refuse the feature; set `server_version: "x.y.z"` in the connection config
  when automatic detection is unavailable.
  """

  alias Milvex.Config
  alias Milvex.Connection
  alias Milvex.Milvus.Proto.Milvus.GetVersionRequest
  alias Milvex.Milvus.Proto.Milvus.MilvusService
  alias Milvex.RPC

  @doc "Returns the configured or detected version for the selected channel."
  @spec get(GenServer.server(), keyword()) :: {:ok, Version.t()} | {:error, Milvex.Error.t()}
  def get(conn, opts \\ []) do
    with {:ok, channel, config} <- Connection.get_channel(conn, opts) do
      case config.server_version do
        %Version{} = version -> {:ok, version}
        nil -> detect(conn, channel, config, opts)
      end
    end
  end

  defp detect(conn, channel, config, opts) do
    with {:ok, response} <-
           RPC.call(
             fn -> {:ok, channel, config} end,
             MilvusService.Stub,
             :get_version,
             %GetVersionRequest{},
             Config.merge_rpc_opts(config, opts)
           ),
         {:ok, response} <- RPC.with_status_check(response, "GetVersion"),
         {:ok, version} <- parse(response.version) do
      Connection.put_server_version(conn, channel, version)
      {:ok, version}
    else
      :error -> {:error, unknown_error(nil)}
      {:error, _} = error -> error
    end
  end

  @doc "Refuses a feature unless the server satisfies the version requirement."
  @spec require(GenServer.server(), String.t(), String.t(), keyword()) ::
          :ok | {:error, Milvex.Error.t()}
  def require(conn, requirement, feature, opts \\ []) do
    case get(conn, opts) do
      {:ok, version} ->
        if Version.match?(version, requirement) do
          :ok
        else
          {:error,
           Milvex.Errors.Invalid.exception(
             code: :server_version_unsupported,
             field: feature,
             message: "requires Milvus #{requirement}, connected server is #{version}"
           )}
        end

      {:error, %Milvex.Errors.Invalid{code: :server_version_unknown}} ->
        {:error, unknown_error(feature)}

      {:error, _} = error ->
        error
    end
  end

  defp unknown_error(feature) do
    Milvex.Errors.Invalid.exception(
      code: :server_version_unknown,
      field: feature,
      message:
        "Cannot determine the Milvus server version; set server_version: \"x.y.z\" in the connection config"
    )
  end

  @doc "Parses the major, minor and patch version, discarding any suffix."
  @spec parse(String.t()) :: {:ok, Version.t()} | :error
  def parse(raw) when is_binary(raw) do
    case Regex.run(~r/^v?(\d+)\.(\d+)\.(\d+)/, String.trim(raw), capture: :all_but_first) do
      [major, minor, patch] -> Version.parse("#{major}.#{minor}.#{patch}")
      nil -> :error
    end
  end
end
