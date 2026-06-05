defmodule Milvex.OrderByTest do
  use ExUnit.Case, async: true

  alias Milvex.Milvus.Proto.Common.KeyValuePair
  alias Milvex.OrderBy

  describe "to_param/1" do
    test "returns nil for nil" do
      assert {:ok, nil} = OrderBy.to_param(nil)
    end

    test "returns nil for empty list" do
      assert {:ok, nil} = OrderBy.to_param([])
    end

    test "single atom field defaults to asc" do
      assert {:ok, %KeyValuePair{key: "order_by_fields", value: "price:asc"}} =
               OrderBy.to_param(:price)
    end

    test "single string field defaults to asc" do
      assert {:ok, %KeyValuePair{value: "price:asc"}} = OrderBy.to_param("price")
    end

    test "list of fields are all ascending" do
      assert {:ok, %KeyValuePair{value: "price:asc,rating:asc"}} =
               OrderBy.to_param([:price, :rating])
    end

    test "keyword directions preserve order" do
      assert {:ok, %KeyValuePair{value: "price:desc,rating:asc"}} =
               OrderBy.to_param(desc: :price, asc: :rating)
    end

    test "single keyword direction" do
      assert {:ok, %KeyValuePair{value: "price:desc"}} = OrderBy.to_param(desc: :price)
    end

    test "mixed bare field and keyword direction preserves order" do
      assert {:ok, %KeyValuePair{value: "price:asc,rating:desc"}} =
               OrderBy.to_param([:price, desc: :rating])
    end

    test "string field names are accepted with direction" do
      assert {:ok, %KeyValuePair{value: "price:desc"}} = OrderBy.to_param(desc: "price")
    end

    test "rejects invalid direction" do
      assert {:error, %Milvex.Errors.Invalid{field: :order_by}} = OrderBy.to_param(up: :price)
    end

    test "rejects blank field name" do
      assert {:error, %Milvex.Errors.Invalid{field: :order_by}} = OrderBy.to_param("   ")
    end

    test "rejects malformed entry" do
      assert {:error, %Milvex.Errors.Invalid{field: :order_by}} = OrderBy.to_param([123])
    end

    test "rejects a boolean as a field name" do
      assert {:error, %Milvex.Errors.Invalid{field: :order_by}} = OrderBy.to_param([true])
    end

    test "trims surrounding whitespace from field names" do
      assert {:ok, %Milvex.Milvus.Proto.Common.KeyValuePair{value: "price:asc"}} =
               OrderBy.to_param("  price  ")
    end
  end
end
