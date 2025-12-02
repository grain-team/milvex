defmodule Milvex.Errors.Connection do
  @moduledoc """
  Errors related to connection establishment, network issues, or disconnections.

  Used when:
  - Unable to establish gRPC connection
  - Connection timeout
  - Network unreachable
  - Connection lost during operation
  """

  use Splode.Error,
    fields: [:reason, :host, :port, :retriable],
    class: :connection

  @type t :: %__MODULE__{
          reason: String.t() | atom(),
          host: String.t() | nil,
          port: integer() | nil,
          retriable: boolean() | nil
        }

  def message(%{reason: reason, host: host, port: port})
      when not is_nil(host) and not is_nil(port) do
    "Connection failed to #{host}:#{port}: #{format_reason(reason)}"
  end

  def message(%{reason: reason}) do
    "Connection error: #{format_reason(reason)}"
  end

  defp format_reason(reason) when is_atom(reason), do: to_string(reason)
  defp format_reason(reason) when is_binary(reason), do: reason
  defp format_reason(reason), do: inspect(reason)
end
