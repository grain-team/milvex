defmodule Milvex.ServerVersion do
  @moduledoc """
  Server version detection and feature gating.

  Each connection detects the version once per channel, right after it
  connects, and hands it out with the channel as `config.server_version`.

  Groups B to F must call `require/4` before sending a 3.0-only field or RPC,
  for example `require(conn, ">= 3.0.0", "feature", opts)`. Unknown versions
  refuse the feature; set `server_version: "x.y.z"` in the connection config
  when automatic detection is unavailable.
  """

  require Logger

  alias Milvex.Config
  alias Milvex.Connection
  alias Milvex.Milvus.Proto.Milvus.GetVersionRequest
  alias Milvex.Milvus.Proto.Milvus.MilvusService
  alias Milvex.RPC

  @detect_timeout 5_000

  @doc """
  Returns the configured version, or asks the server over `channel`.

  Runs inside the connection process, so it uses a short fixed timeout, does
  not retry, and returns `nil` instead of failing the connect.
  """
  @spec detect(Connection.channel(), Config.t()) :: Version.t() | nil
  def detect(_channel, %{server_version: %Version{} = version}), do: version

  def detect(channel, _config) do
    with {:ok, response} <-
           MilvusService.Stub.get_version(channel, %GetVersionRequest{}, timeout: @detect_timeout),
         {:ok, response} <- RPC.with_status_check(response, "GetVersion"),
         {:ok, version} <- parse(response.version) do
      version
    else
      reason -> undetected(reason)
    end
  catch
    kind, reason -> undetected({kind, reason})
  end

  defp undetected(reason) do
    Logger.warning(
      "Could not detect the Milvus server version: #{inspect(reason)}; " <>
        "version-gated features are refused on this channel"
    )

    nil
  end

  @doc "Returns the configured or detected version for the selected channel."
  @spec get(GenServer.server(), keyword()) :: {:ok, Version.t()} | {:error, Milvex.Error.t()}
  def get(conn, opts \\ []) do
    with {:ok, _channel, config} <- Connection.get_channel(conn, opts) do
      case config.server_version do
        %Version{} = version -> {:ok, version}
        nil -> {:error, unknown_error(nil)}
      end
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
