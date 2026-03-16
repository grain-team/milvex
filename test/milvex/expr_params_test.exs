defmodule Milvex.ExprParamsTest do
  use ExUnit.Case, async: true

  alias Milvex.ExprParams
  alias Milvex.Milvus.Proto.Schema.BoolArray
  alias Milvex.Milvus.Proto.Schema.DoubleArray
  alias Milvex.Milvus.Proto.Schema.LongArray
  alias Milvex.Milvus.Proto.Schema.StringArray
  alias Milvex.Milvus.Proto.Schema.TemplateArrayValue
  alias Milvex.Milvus.Proto.Schema.TemplateValue

  describe "to_proto/1" do
    test "converts boolean values" do
      result = ExprParams.to_proto(%{"active" => true})

      assert %{"active" => %TemplateValue{val: {:bool_val, true}}} = result
    end

    test "converts integer values" do
      result = ExprParams.to_proto(%{"age" => 25})

      assert %{"age" => %TemplateValue{val: {:int64_val, 25}}} = result
    end

    test "converts float values" do
      result = ExprParams.to_proto(%{"score" => 0.95})

      assert %{"score" => %TemplateValue{val: {:float_val, 0.95}}} = result
    end

    test "converts string values" do
      result = ExprParams.to_proto(%{"city" => "Berlin"})

      assert %{"city" => %TemplateValue{val: {:string_val, "Berlin"}}} = result
    end

    test "converts list of integers to array value" do
      result = ExprParams.to_proto(%{"ids" => [1, 2, 3]})

      assert %{"ids" => %TemplateValue{val: {:array_val, %TemplateArrayValue{}}}} = result

      assert {:long_data, %LongArray{data: [1, 2, 3]}} =
               result["ids"].val |> elem(1) |> Map.get(:data)
    end

    test "converts list of floats to array value" do
      result = ExprParams.to_proto(%{"scores" => [0.1, 0.2, 0.3]})

      assert {:double_data, %DoubleArray{data: [0.1, 0.2, 0.3]}} =
               result["scores"].val |> elem(1) |> Map.get(:data)
    end

    test "converts list of strings to array value" do
      result = ExprParams.to_proto(%{"cities" => ["Berlin", "Tokyo"]})

      assert {:string_data, %StringArray{data: ["Berlin", "Tokyo"]}} =
               result["cities"].val |> elem(1) |> Map.get(:data)
    end

    test "converts list of booleans to array value" do
      result = ExprParams.to_proto(%{"flags" => [true, false, true]})

      assert {:bool_data, %BoolArray{data: [true, false, true]}} =
               result["flags"].val |> elem(1) |> Map.get(:data)
    end

    test "converts multiple params in a single map" do
      result = ExprParams.to_proto(%{"age" => 25, "city" => "Berlin", "active" => true})

      assert %TemplateValue{val: {:int64_val, 25}} = result["age"]
      assert %TemplateValue{val: {:string_val, "Berlin"}} = result["city"]
      assert %TemplateValue{val: {:bool_val, true}} = result["active"]
    end

    test "returns empty map for nil input" do
      assert %{} = ExprParams.to_proto(nil)
    end

    test "returns empty map for empty map input" do
      assert %{} = ExprParams.to_proto(%{})
    end

    test "converts atom keys to string keys" do
      result = ExprParams.to_proto(%{age: 25})

      assert %{"age" => %TemplateValue{val: {:int64_val, 25}}} = result
    end
  end
end
