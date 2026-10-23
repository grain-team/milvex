defmodule Milvex.Ranker.DecayRanker do
  @moduledoc """
  Decay function reranker for hybrid search.

  Applies a decay function (Gaussian, exponential, or linear) to a numeric field,
  scoring documents higher when the field value is closer to the origin.
  Useful for time-based relevance decay.

  The field must be numeric (`:int8` to `:int64`, `:float`, `:double`). Milvus 3
  rejects `:timestamp` (Timestamptz) fields, so for time decay store epoch
  seconds in an `:int64` field and use an epoch-seconds `:origin`.

  ## Fields

    - `:function` - Decay curve: `:gauss`, `:exp`, or `:linear`
    - `:field` - Name of the numeric field to apply decay to
    - `:origin` - Center point (e.g., a timestamp)
    - `:scale` - Distance from origin at which score equals `:decay`
    - `:offset` - Zone around origin with full score (default: 0)
    - `:decay` - Score at `:scale` distance from origin (default: 0.5)
  """

  @type t :: %__MODULE__{
          function: :gauss | :exp | :linear,
          field: String.t(),
          origin: integer(),
          scale: pos_integer(),
          offset: non_neg_integer(),
          decay: float()
        }

  defstruct [:function, :field, :origin, :scale, offset: 0, decay: 0.5]
end
