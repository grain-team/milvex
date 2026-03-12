defmodule Milvex.Highlighter do
  @moduledoc """
  Builder functions for search result highlighting.

  Two highlighting strategies are available:

  - **Lexical** - matches based on exact token overlap (BM25 search)
  - **Semantic** - matches based on meaning similarity using a deployed model

  ## Examples

      {:ok, hl} = Highlighter.lexical("content")
      {:ok, hl} = Highlighter.semantic(["what is AI?"], ["content", "title"],
        model_deployment_id: "my-model"
      )
  """

  alias Milvex.Errors.Invalid

  defstruct [:type, :params]

  @type t :: %__MODULE__{
          type: :lexical | :semantic,
          params: map()
        }

  @doc """
  Creates a lexical highlighter for the given field.

  Lexical highlighting matches based on exact token overlap between
  the query and the document text. Works with BM25 search.

  ## Options

    - `:pre_tag` - Tag inserted before highlighted text (default: `"<b>"`)
    - `:post_tag` - Tag inserted after highlighted text (default: `"</b>"`)

  ## Examples

      {:ok, hl} = Highlighter.lexical("content")
      {:ok, hl} = Highlighter.lexical("content", pre_tag: "<em>", post_tag: "</em>")
  """
  @spec lexical(String.t(), keyword()) :: {:ok, t()} | {:error, Invalid.t()}
  def lexical(field, opts \\ [])

  def lexical(field, _opts) when not is_binary(field) or field == "" do
    {:error, Invalid.exception(field: :field, message: "must be a non-empty string")}
  end

  def lexical(field, opts) do
    pre_tag = Keyword.get(opts, :pre_tag, "<b>")
    post_tag = Keyword.get(opts, :post_tag, "</b>")

    with :ok <- validate_tag(:pre_tag, pre_tag),
         :ok <- validate_tag(:post_tag, post_tag) do
      params = %{
        pre_tags: [pre_tag],
        post_tags: [post_tag],
        highlight_field: field,
        highlight_search_text: true
      }

      {:ok, %__MODULE__{type: :lexical, params: params}}
    end
  end

  @doc """
  Creates a semantic highlighter.

  Semantic highlighting matches based on meaning similarity using a
  deployed model. Requires explicit queries and input fields.

  ## Parameters

    - `queries` - List of search query strings to match against documents
    - `input_fields` - List of field names to highlight

  ## Options

    - `:pre_tags` - List of tags inserted before highlighted text
    - `:post_tags` - List of tags inserted after highlighted text
    - `:threshold` - Minimum confidence score (0.0 to 1.0) to trigger highlighting
    - `:highlight_only` - If true, returns only highlighted snippets instead of full text
    - `:model_deployment_id` - ID of the deployed model for semantic inference
    - `:max_client_batch_size` - Limits items processed in a single batch

  ## Examples

      {:ok, hl} = Highlighter.semantic(["what is AI?"], ["content"])
      {:ok, hl} = Highlighter.semantic(["search query"], ["title", "body"],
        threshold: 0.5,
        model_deployment_id: "my-model"
      )
  """
  @spec semantic([String.t()], [String.t()], keyword()) :: {:ok, t()} | {:error, Invalid.t()}
  def semantic(queries, input_fields, opts \\ [])

  def semantic(queries, _input_fields, _opts) when not is_list(queries) or queries == [] do
    {:error, Invalid.exception(field: :queries, message: "must be a non-empty list of strings")}
  end

  def semantic(_queries, input_fields, _opts)
      when not is_list(input_fields) or input_fields == [] do
    {:error,
     Invalid.exception(field: :input_fields, message: "must be a non-empty list of strings")}
  end

  def semantic(queries, input_fields, opts) do
    with :ok <- validate_string_list(:queries, queries),
         :ok <- validate_string_list(:input_fields, input_fields) do
      params =
        %{queries: queries, input_fields: input_fields}
        |> put_optional(opts, :pre_tags)
        |> put_optional(opts, :post_tags)
        |> put_optional(opts, :threshold)
        |> put_optional(opts, :highlight_only)
        |> put_optional(opts, :model_deployment_id)
        |> put_optional(opts, :max_client_batch_size)

      {:ok, %__MODULE__{type: :semantic, params: params}}
    end
  end

  defp validate_tag(_name, value) when is_binary(value), do: :ok

  defp validate_tag(name, _value) do
    {:error, Invalid.exception(field: name, message: "must be a string")}
  end

  defp validate_string_list(name, list) do
    if Enum.all?(list, &is_binary/1) do
      :ok
    else
      {:error, Invalid.exception(field: name, message: "all elements must be strings")}
    end
  end

  defp put_optional(params, opts, key) do
    case Keyword.get(opts, key) do
      nil -> params
      value -> Map.put(params, key, value)
    end
  end
end
