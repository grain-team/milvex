defmodule Milvex.Errors.Unknown do
  @moduledoc """
  Fallback for unexpected or unclassified errors.

  Used when:
  - An unexpected exception occurs
  - Error cannot be classified into other categories
  - Wrapping third-party library errors
  """

  use Splode.Error,
    fields: [:error, :context],
    class: :unknown

  @type t :: %__MODULE__{
          error: term(),
          context: map() | nil
        }

  def message(%{error: error, context: context}) when not is_nil(context) do
    "Unknown error: #{format_error(error)} (context: #{inspect(context)})"
  end

  def message(%{error: error}) do
    "Unknown error: #{format_error(error)}"
  end

  defp format_error(%{__exception__: true} = error), do: Exception.message(error)
  defp format_error(error) when is_binary(error), do: error
  defp format_error(error), do: inspect(error)
end
