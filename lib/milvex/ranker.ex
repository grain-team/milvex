defmodule Milvex.Ranker do
  @moduledoc """
  Builder functions for hybrid search rerankers.

  Provides three reranking strategies:
  - `weighted/1` - Weighted average scoring
  - `rrf/1` - Reciprocal Rank Fusion
  - `decay/2` - Decay function scoring based on field proximity

  ## Examples

      {:ok, ranker} = Ranker.weighted([0.7, 0.3])
      {:ok, ranker} = Ranker.rrf(k: 60)
      {:ok, ranker} = Ranker.decay(:gauss, field: "timestamp", origin: 1_710_000_000, scale: 86_400)
  """

  alias Milvex.Errors.Invalid
  alias Milvex.Ranker.DecayRanker
  alias Milvex.Ranker.RRFRanker
  alias Milvex.Ranker.WeightedRanker

  @doc """
  Creates a weighted ranker with the given weights.

  Each weight corresponds to a sub-search in the hybrid search.
  The number of weights must match the number of searches.

  ## Examples

      {:ok, ranker} = Ranker.weighted([0.8, 0.2])
  """
  @spec weighted([number()]) :: {:ok, WeightedRanker.t()} | {:error, Invalid.t()}
  def weighted([_ | _] = weights) do
    if Enum.all?(weights, &is_number/1) do
      {:ok, %WeightedRanker{weights: weights}}
    else
      {:error, Invalid.exception(field: :weights, message: "all weights must be numbers")}
    end
  end

  def weighted(_) do
    {:error, Invalid.exception(field: :weights, message: "must be a non-empty list of numbers")}
  end

  @doc """
  Creates an RRF (Reciprocal Rank Fusion) ranker.

  ## Options

    - `:k` - Smoothness parameter (default: 60, must be positive)

  ## Examples

      {:ok, ranker} = Ranker.rrf()
      {:ok, ranker} = Ranker.rrf(k: 100)
  """
  @spec rrf(keyword()) :: {:ok, RRFRanker.t()} | {:error, Invalid.t()}
  def rrf(opts \\ []) do
    k = Keyword.get(opts, :k, 60)

    if is_integer(k) and k > 0 do
      {:ok, %RRFRanker{k: k}}
    else
      {:error, Invalid.exception(field: :k, message: "must be a positive integer")}
    end
  end

  @valid_decay_functions [:gauss, :exp, :linear]

  @doc """
  Creates a decay function ranker for hybrid search.

  Applies a decay curve to a numeric field, scoring documents higher
  when the field value is closer to the origin.

  ## Parameters

    - `function` - Decay curve: `:gauss`, `:exp`, or `:linear`
    - `opts` - Keyword list of options

  ## Options

    - `:field` - (required) Name of the numeric field
    - `:origin` - (required) Center point (integer)
    - `:scale` - (required) Distance from origin where score = decay (positive integer)
    - `:offset` - Zone around origin with full score (default: 0)
    - `:decay` - Score at scale distance (default: 0.5, must be between 0 and 1 exclusive)

  ## Examples

      {:ok, ranker} = Ranker.decay(:gauss, field: "timestamp", origin: 1_710_000_000, scale: 86_400)
      {:ok, ranker} = Ranker.decay(:exp, field: "publish_time", origin: 1_710_000_000, scale: 3600, offset: 300, decay: 0.3)
  """
  @spec decay(:gauss | :exp | :linear, keyword()) ::
          {:ok, DecayRanker.t()} | {:error, Invalid.t()}
  def decay(function, opts) when function in @valid_decay_functions do
    field = opts[:field]
    origin = opts[:origin]
    scale = opts[:scale]
    offset = Keyword.get(opts, :offset, 0)
    decay_val = Keyword.get(opts, :decay, 0.5)

    field = if is_atom(field) and not is_nil(field), do: Atom.to_string(field), else: field

    with :ok <- validate_decay_params(field, origin, scale, offset, decay_val) do
      {:ok,
       %DecayRanker{
         function: function,
         field: field,
         origin: origin,
         scale: scale,
         offset: offset,
         decay: decay_val
       }}
    end
  end

  def decay(function, _opts) do
    {:error,
     Invalid.exception(
       field: :function,
       message: "must be one of: :gauss, :exp, :linear, got: #{inspect(function)}"
     )}
  end

  defp validate_decay_params(field, origin, scale, offset, decay_val) do
    with :ok <- validate_decay_field(field),
         :ok <- validate_decay_origin(origin),
         :ok <- validate_decay_scale(scale),
         :ok <- validate_decay_offset(offset) do
      validate_decay_value(decay_val)
    end
  end

  defp validate_decay_field(field) when is_binary(field) and field != "", do: :ok

  defp validate_decay_field(_),
    do: {:error, Invalid.exception(field: :field, message: "must be a non-empty string")}

  defp validate_decay_origin(origin) when is_integer(origin), do: :ok

  defp validate_decay_origin(_),
    do: {:error, Invalid.exception(field: :origin, message: "must be an integer")}

  defp validate_decay_scale(scale) when is_integer(scale) and scale > 0, do: :ok

  defp validate_decay_scale(_),
    do: {:error, Invalid.exception(field: :scale, message: "must be a positive integer")}

  defp validate_decay_offset(offset) when is_integer(offset) and offset >= 0, do: :ok

  defp validate_decay_offset(_),
    do: {:error, Invalid.exception(field: :offset, message: "must be a non-negative integer")}

  defp validate_decay_value(val) when is_number(val) and val > 0 and val < 1, do: :ok

  defp validate_decay_value(_),
    do:
      {:error,
       Invalid.exception(field: :decay, message: "must be a number between 0 and 1 (exclusive)")}
end
