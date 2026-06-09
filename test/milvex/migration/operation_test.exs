defmodule Milvex.Migration.OperationTest do
  use ExUnit.Case, async: true

  alias Milvex.Function
  alias Milvex.Index
  alias Milvex.Migration.Operation
  alias Milvex.Schema
  alias Milvex.Schema.Field

  describe "build/6 — version-aware classification" do
    test "drop_field on Milvus 2.5.x requires release" do
      op = Operation.build(:drop_field, :destructive, "movies", %{field_name: "old"}, "2.5.4")
      assert op.requires_release == true
      assert op.kind == :drop_field
      assert op.category == :destructive
      assert op.collection_name == "movies"
      assert op.payload == %{field_name: "old"}
    end

    test "drop_field on Milvus 2.6.x does not require release" do
      op = Operation.build(:drop_field, :destructive, "movies", %{field_name: "old"}, "2.6.1")
      assert op.requires_release == false
    end

    test "drop_function on 2.5 requires release; on 2.6 does not" do
      op_25 =
        Operation.build(:drop_function, :destructive, "c", %{function_name: "fn"}, "2.5.10")

      op_26 =
        Operation.build(:drop_function, :destructive, "c", %{function_name: "fn"}, "2.6.0")

      assert op_25.requires_release == true
      assert op_26.requires_release == false
    end

    test "drop_index always requires release regardless of version" do
      for v <- ["2.4.0", "2.5.10", "2.6.1", "2.7.0"] do
        op = Operation.build(:drop_index, :destructive, "c", %{index_name: "i"}, v)
        assert op.requires_release == true, "expected drop_index on #{v} to require release"
      end
    end

    test "recreate_index always requires release regardless of version" do
      for v <- ["2.4.0", "2.5.10", "2.6.1", "2.7.0"] do
        op =
          Operation.build(
            :recreate_index,
            :destructive,
            "c",
            %{field_name: "v", old: %{}, new: %{}},
            v
          )

        assert op.requires_release == true,
               "expected recreate_index on #{v} to require release"
      end
    end

    test "additive kinds never require release on 2.6.1" do
      kinds = [
        {:add_field, %{field: Field.new("x", :int64)}},
        {:alter_field, %{field_name: "x", changes: %{}}},
        {:create_index, %{index: Index.new("v", :hnsw, :cosine)}},
        {:add_function, %{function: Function.new("f", :BM25)}},
        {:alter_function, %{function_name: "f", changes: %{}}},
        {:create_collection, %{schema: %Schema{name: "x", fields: []}}}
      ]

      for {kind, payload} <- kinds do
        op = Operation.build(kind, :additive, "c", payload, "2.6.1")

        assert op.requires_release == false,
               "expected #{kind} to not require release on 2.6.1"
      end
    end

    test "version coercion: v-prefix, dev suffix, plain semver all behave the same" do
      for v <- ["v2.6.1", "2.6.1-dev", "2.6.1"] do
        op = Operation.build(:drop_field, :destructive, "c", %{field_name: "x"}, v)
        assert op.requires_release == false, "version #{v} should classify as 2.6+"
      end

      for v <- ["v2.5.4", "2.5.4-rc1", "2.5.4"] do
        op = Operation.build(:drop_field, :destructive, "c", %{field_name: "x"}, v)
        assert op.requires_release == true, "version #{v} should classify as 2.5"
      end
    end

    test "build accepts an optional :reason via opts" do
      op =
        Operation.build(
          :drop_field,
          :destructive,
          "c",
          %{field_name: "x"},
          "2.6.1",
          reason: "user requested"
        )

      assert op.reason == "user requested"
    end
  end

  describe "requires_release?/2" do
    test "drop_index always true" do
      assert Operation.requires_release?(:drop_index, "2.6.1") == true
      assert Operation.requires_release?(:drop_index, "2.5.4") == true
    end

    test "recreate_index always true" do
      assert Operation.requires_release?(:recreate_index, "2.6.1") == true
      assert Operation.requires_release?(:recreate_index, "2.4.0") == true
    end

    test "drop_field gated by 2.6.0" do
      assert Operation.requires_release?(:drop_field, "2.5.99") == true
      assert Operation.requires_release?(:drop_field, "2.6.0") == false
      assert Operation.requires_release?(:drop_field, "2.6.1") == false
    end

    test "drop_function gated by 2.6.0" do
      assert Operation.requires_release?(:drop_function, "2.5.10") == true
      assert Operation.requires_release?(:drop_function, "2.6.0") == false
    end

    test "additive kinds always false" do
      for kind <- [
            :add_field,
            :alter_field,
            :create_index,
            :add_function,
            :alter_function,
            :create_collection,
            :description_change
          ] do
        assert Operation.requires_release?(kind, "2.5.0") == false
        assert Operation.requires_release?(kind, "2.6.1") == false
      end
    end
  end

  describe "to_map/1" do
    test ":add_field returns a map with normalized field projection (drops nil keys)" do
      field = Field.varchar("description", 1024, nullable: true)
      op = Operation.build(:add_field, :additive, "movies", %{field: field}, "2.6.1")

      assert %{
               kind: :add_field,
               category: :additive,
               field: %{
                 name: "description",
                 data_type: :varchar,
                 max_length: 1024,
                 nullable: true
               }
             } = Operation.to_map(op)

      result = Operation.to_map(op)
      refute Map.has_key?(result.field, :dimension)
      refute Map.has_key?(result.field, :description)
      refute Map.has_key?(result.field, :default_value)
    end

    test ":drop_field returns kind/category/field_name" do
      op = Operation.build(:drop_field, :destructive, "movies", %{field_name: "legacy"}, "2.6.1")

      assert Operation.to_map(op) == %{
               kind: :drop_field,
               category: :destructive,
               field_name: "legacy"
             }
    end

    test ":alter_field includes the changes diff" do
      changes = %{max_length: [256, 512]}

      op =
        Operation.build(
          :alter_field,
          :additive,
          "movies",
          %{field_name: "title", changes: changes},
          "2.6.1"
        )

      assert Operation.to_map(op) == %{
               kind: :alter_field,
               category: :additive,
               field_name: "title",
               changes: %{max_length: [256, 512]}
             }
    end

    test ":description_change includes from/to" do
      op =
        Operation.build(
          :description_change,
          :descriptive,
          "movies",
          %{field_name: "title", from: "old", to: "new"},
          "2.6.1"
        )

      assert Operation.to_map(op) == %{
               kind: :description_change,
               category: :descriptive,
               field_name: "title",
               from: "old",
               to: "new"
             }
    end

    test ":create_index includes index identifying info" do
      idx = Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)
      op = Operation.build(:create_index, :additive, "movies", %{index: idx}, "2.6.1")

      result = Operation.to_map(op)
      assert result.kind == :create_index
      assert result.category == :additive
      assert result.index.field_name == "embedding"
      assert result.index.index_type == :hnsw
      assert result.index.metric_type == :cosine
    end

    test ":drop_index includes field_name + index_name" do
      op =
        Operation.build(
          :drop_index,
          :destructive,
          "movies",
          %{field_name: "embedding", index_name: "emb_idx"},
          "2.6.1"
        )

      assert Operation.to_map(op) == %{
               kind: :drop_index,
               category: :destructive,
               field_name: "embedding",
               index_name: "emb_idx"
             }
    end

    test ":recreate_index includes both old and new index summaries" do
      old_idx = Index.hnsw("embedding", :cosine)
      new_idx = Index.hnsw("embedding", :l2)

      op =
        Operation.build(
          :recreate_index,
          :destructive,
          "movies",
          %{field_name: "embedding", old: old_idx, new: new_idx},
          "2.6.1"
        )

      result = Operation.to_map(op)
      assert result.kind == :recreate_index
      assert result.field_name == "embedding"
      assert result.old.metric_type == :cosine
      assert result.new.metric_type == :l2
    end

    test ":add_function carries name + params from payload" do
      fn_struct = Function.new("bm25_fn", :BM25)
      op = Operation.build(:add_function, :additive, "movies", %{function: fn_struct}, "2.6.1")

      result = Operation.to_map(op)
      assert result.kind == :add_function
      assert result.function.name == "bm25_fn"
      assert result.function.type == :BM25
    end

    test ":alter_function carries name + changes" do
      op =
        Operation.build(
          :alter_function,
          :additive,
          "movies",
          %{function_name: "bm25_fn", changes: %{params: [%{}, %{"k1" => "1.5"}]}},
          "2.6.1"
        )

      result = Operation.to_map(op)
      assert result.kind == :alter_function
      assert result.function_name == "bm25_fn"
      assert result.changes == %{params: [%{}, %{"k1" => "1.5"}]}
    end

    test ":drop_function carries name" do
      op =
        Operation.build(
          :drop_function,
          :destructive,
          "movies",
          %{function_name: "bm25_fn"},
          "2.6.1"
        )

      assert Operation.to_map(op) == %{
               kind: :drop_function,
               category: :destructive,
               function_name: "bm25_fn"
             }
    end

    test ":create_collection includes schema" do
      schema = %Schema{name: "movies", fields: [Field.primary_key("id", :int64)]}
      op = Operation.build(:create_collection, :additive, "movies", %{schema: schema}, "2.6.1")

      result = Operation.to_map(op)
      assert result.kind == :create_collection
      assert result.schema.name == "movies"
    end

  end

  describe "to_line/1" do
    test "additive add_field starts with + and contains kind and field name" do
      field = Field.varchar("description", 1024, nullable: true)
      op = Operation.build(:add_field, :additive, "movies", %{field: field}, "2.6.1")

      line = op |> Operation.to_line() |> IO.iodata_to_binary()
      assert String.starts_with?(line, "+")
      assert String.contains?(line, "add field")
      assert String.contains?(line, "description")
      refute String.contains?(line, "\n")
    end

    test "destructive drop_field starts with - and contains kind and name" do
      op =
        Operation.build(
          :drop_field,
          :destructive,
          "movies",
          %{field_name: "legacy_score"},
          "2.6.1"
        )

      line = op |> Operation.to_line() |> IO.iodata_to_binary()
      assert String.starts_with?(line, "-")
      assert String.contains?(line, "drop field")
      assert String.contains?(line, "legacy_score")
      refute String.contains?(line, "\n")
    end

    test "impossible operation starts with !" do
      op =
        Operation.build(
          :alter_field,
          :impossible,
          "movies",
          %{field_name: "id", changes: %{data_type: [:int64, :varchar]}},
          "2.6.1",
          reason: "cannot change pk type"
        )

      line = op |> Operation.to_line() |> IO.iodata_to_binary()
      assert String.starts_with?(line, "!")
    end

    test "descriptive description_change starts with ~" do
      op =
        Operation.build(
          :description_change,
          :descriptive,
          "movies",
          %{field_name: "title", from: "old", to: "new"},
          "2.6.1"
        )

      line = op |> Operation.to_line() |> IO.iodata_to_binary()
      assert String.starts_with?(line, "~")
    end
  end
end
