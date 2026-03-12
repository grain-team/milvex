defmodule Milvex.RankerTest do
  use ExUnit.Case, async: true

  alias Milvex.Ranker
  alias Milvex.Ranker.DecayRanker
  alias Milvex.Ranker.RRFRanker
  alias Milvex.Ranker.WeightedRanker

  describe "weighted/1" do
    test "returns {:ok, ranker} with valid weights" do
      assert {:ok, %WeightedRanker{weights: [0.7, 0.3]}} = Ranker.weighted([0.7, 0.3])
    end

    test "returns {:ok, ranker} with single weight" do
      assert {:ok, %WeightedRanker{weights: [1.0]}} = Ranker.weighted([1.0])
    end

    test "returns {:error, _} with empty list" do
      assert {:error, error} = Ranker.weighted([])
      assert error.field == :weights
    end

    test "returns {:error, _} with non-list" do
      assert {:error, error} = Ranker.weighted(0.5)
      assert error.field == :weights
    end
  end

  describe "rrf/1" do
    test "returns {:ok, ranker} with default k" do
      assert {:ok, %RRFRanker{k: 60}} = Ranker.rrf()
    end

    test "returns {:ok, ranker} with custom k" do
      assert {:ok, %RRFRanker{k: 100}} = Ranker.rrf(k: 100)
    end

    test "returns {:error, _} with invalid k" do
      assert {:error, error} = Ranker.rrf(k: 0)
      assert error.field == :k
    end

    test "returns {:error, _} with negative k" do
      assert {:error, error} = Ranker.rrf(k: -10)
      assert error.field == :k
    end
  end

  describe "decay/2" do
    test "returns {:ok, ranker} with valid gauss params" do
      assert {:ok,
              %DecayRanker{
                function: :gauss,
                field: "timestamp",
                origin: 1_710_000_000,
                scale: 86_400,
                offset: 0,
                decay: 0.5
              }} = Ranker.decay(:gauss, field: "timestamp", origin: 1_710_000_000, scale: 86_400)
    end

    test "returns {:ok, ranker} with all params specified" do
      assert {:ok,
              %DecayRanker{
                function: :exp,
                field: "ts",
                origin: 100,
                scale: 10,
                offset: 5,
                decay: 0.3
              }} = Ranker.decay(:exp, field: "ts", origin: 100, scale: 10, offset: 5, decay: 0.3)
    end

    test "returns {:ok, ranker} with linear function" do
      assert {:ok, %DecayRanker{function: :linear}} =
               Ranker.decay(:linear, field: "age", origin: 0, scale: 100)
    end

    test "normalizes atom field to string" do
      assert {:ok, %DecayRanker{field: "timestamp"}} =
               Ranker.decay(:gauss, field: :timestamp, origin: 0, scale: 1)
    end

    test "returns {:error, _} with invalid function" do
      assert {:error, error} = Ranker.decay(:invalid, field: "ts", origin: 0, scale: 1)
      assert error.field == :function
    end

    test "returns {:error, _} with missing field" do
      assert {:error, error} = Ranker.decay(:gauss, origin: 0, scale: 1)
      assert error.field == :field
    end

    test "returns {:error, _} with empty field" do
      assert {:error, error} = Ranker.decay(:gauss, field: "", origin: 0, scale: 1)
      assert error.field == :field
    end

    test "returns {:error, _} with non-integer origin" do
      assert {:error, error} = Ranker.decay(:gauss, field: "ts", origin: 1.5, scale: 1)
      assert error.field == :origin
    end

    test "returns {:error, _} with zero scale" do
      assert {:error, error} = Ranker.decay(:gauss, field: "ts", origin: 0, scale: 0)
      assert error.field == :scale
    end

    test "returns {:error, _} with negative offset" do
      assert {:error, error} = Ranker.decay(:gauss, field: "ts", origin: 0, scale: 1, offset: -1)
      assert error.field == :offset
    end

    test "returns {:error, _} with decay out of range" do
      assert {:error, error} = Ranker.decay(:gauss, field: "ts", origin: 0, scale: 1, decay: 0.0)
      assert error.field == :decay

      assert {:error, error} = Ranker.decay(:gauss, field: "ts", origin: 0, scale: 1, decay: 1.0)
      assert error.field == :decay
    end
  end
end
