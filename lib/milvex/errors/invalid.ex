defmodule Milvex.Errors.Invalid do
  @moduledoc """
  Errors for invalid input, validation failures, or constraint violations.

  Used when user-provided data fails validation, such as:
  - Invalid configuration parameters
  - Schema validation failures
  - Missing required fields
  - Type mismatches
  """

  use Splode.Error,
    fields: [:field, :message, :code, :context],
    class: :invalid

  @type t :: %__MODULE__{
          field: String.t() | atom() | nil,
          message: String.t(),
          code: atom() | nil,
          context: map() | nil
        }

  def message(%{field: field, message: msg}) when not is_nil(field) do
    "Invalid #{field}: #{msg}"
  end

  def message(%{message: msg}) do
    "Invalid input: #{msg}"
  end
end
