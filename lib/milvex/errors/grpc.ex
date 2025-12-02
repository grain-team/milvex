defmodule Milvex.Errors.Grpc do
  @moduledoc """
  Errors from gRPC operations or Milvus server responses.

  Used when:
  - Milvus returns an error status code
  - gRPC call fails
  - Server-side validation fails
  - Operation not permitted
  """

  use Splode.Error,
    fields: [:code, :message, :details, :operation],
    class: :grpc

  @type t :: %__MODULE__{
          code: integer() | atom(),
          message: String.t(),
          details: map() | nil,
          operation: String.t() | atom() | nil
        }

  def message(%{operation: op, code: code, message: msg}) when not is_nil(op) do
    "gRPC error in #{op} (code: #{format_code(code)}): #{msg}"
  end

  def message(%{code: code, message: msg}) do
    "gRPC error (code: #{format_code(code)}): #{msg}"
  end

  defp format_code(code) when is_integer(code), do: Integer.to_string(code)
  defp format_code(code) when is_atom(code), do: to_string(code)
  defp format_code(code), do: inspect(code)
end
