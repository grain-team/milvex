defmodule Milvex.ServerVersion do
  @moduledoc """
  Lazy server version detection, cached per established channel.

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

  @table :milvex_server_versions

  @doc "Creates the version cache, owned by the application process."
  @spec create_table() :: :ok
  def create_table do
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
    :ok
  end

  @doc "Returns the cached version without channel lookup or an RPC."
  @spec cached(Connection.channel()) :: {:ok, Version.t()} | :unknown | :miss
  def cached(%GRPC.Channel{ref: ref}) do
    case :ets.lookup(@table, ref) do
      [{^ref, %Version{} = version}] -> {:ok, version}
      [{^ref, :unknown}] -> :unknown
      [] -> :miss
    end
  end

  @doc "Removes a dropped channel's cached version."
  @spec forget(Connection.channel() | nil) :: :ok
  def forget(nil), do: :ok

  def forget(%GRPC.Channel{ref: ref}) do
    :ets.delete(@table, ref)
    :ok
  end

  @doc "Returns the configured or detected version for the selected channel."
  @spec get(GenServer.server(), keyword()) :: {:ok, Version.t()} | {:error, Milvex.Error.t()}
  def get(conn, opts \\ []) do
    with {:ok, channel, config} <- Connection.get_channel(conn, opts) do
      case config.server_version do
        %Version{} = version -> {:ok, version}
        nil -> get_cached(channel, config, opts)
      end
    end
  end

  defp get_cached(channel, config, opts) do
    case cached(channel) do
      {:ok, version} -> {:ok, version}
      :unknown -> {:error, unknown_error(nil)}
      :miss -> detect(channel, config, opts)
    end
  end

  defp detect(channel, config, opts) do
    with {:ok, response} <-
           RPC.call(
             fn -> {:ok, channel, config} end,
             MilvusService.Stub,
             :get_version,
             %GetVersionRequest{},
             Config.merge_rpc_opts(config, opts)
           ),
         {:ok, response} <- RPC.with_status_check(response, "GetVersion") do
      case parse(response.version) do
        {:ok, version} ->
          :ets.insert(@table, {channel.ref, version})
          {:ok, version}

        :error ->
          :ets.insert(@table, {channel.ref, :unknown})
          {:error, unknown_error(nil)}
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
