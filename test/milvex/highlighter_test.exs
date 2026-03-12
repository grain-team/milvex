defmodule Milvex.HighlighterTest do
  use ExUnit.Case, async: true

  alias Milvex.Highlighter

  describe "lexical/2" do
    test "creates highlighter with defaults" do
      assert {:ok, %Highlighter{type: :lexical, params: params}} = Highlighter.lexical("content")
      assert params.pre_tags == ["<b>"]
      assert params.post_tags == ["</b>"]
      assert params.highlight_field == "content"
      assert params.highlight_search_text == true
    end

    test "creates highlighter with custom tags" do
      assert {:ok, %Highlighter{type: :lexical, params: params}} =
               Highlighter.lexical("content", pre_tag: "<em>", post_tag: "</em>")

      assert params.pre_tags == ["<em>"]
      assert params.post_tags == ["</em>"]
    end

    test "rejects empty field" do
      assert {:error, error} = Highlighter.lexical("")
      assert error.field == :field
    end

    test "rejects non-string field" do
      assert {:error, error} = Highlighter.lexical(:text)
      assert error.field == :field
    end

    test "rejects non-string pre_tag" do
      assert {:error, error} = Highlighter.lexical("text", pre_tag: 123)
      assert error.field == :pre_tag
    end

    test "rejects non-string post_tag" do
      assert {:error, error} = Highlighter.lexical("text", post_tag: 456)
      assert error.field == :post_tag
    end
  end

  describe "semantic/3" do
    test "creates highlighter with required params" do
      assert {:ok, %Highlighter{type: :semantic, params: params}} =
               Highlighter.semantic(["what is AI?"], ["content"])

      assert params.queries == ["what is AI?"]
      assert params.input_fields == ["content"]
    end

    test "creates highlighter with all options" do
      assert {:ok, %Highlighter{type: :semantic, params: params}} =
               Highlighter.semantic(["query"], ["title", "body"],
                 pre_tags: ["<em>"],
                 post_tags: ["</em>"],
                 threshold: 0.5,
                 highlight_only: true,
                 model_deployment_id: "my-model",
                 max_client_batch_size: 100
               )

      assert params.queries == ["query"]
      assert params.input_fields == ["title", "body"]
      assert params.pre_tags == ["<em>"]
      assert params.post_tags == ["</em>"]
      assert params.threshold == 0.5
      assert params.highlight_only == true
      assert params.model_deployment_id == "my-model"
      assert params.max_client_batch_size == 100
    end

    test "omits optional params when not provided" do
      assert {:ok, %Highlighter{params: params}} =
               Highlighter.semantic(["q"], ["field"])

      refute Map.has_key?(params, :threshold)
      refute Map.has_key?(params, :highlight_only)
      refute Map.has_key?(params, :model_deployment_id)
    end

    test "rejects empty queries" do
      assert {:error, error} = Highlighter.semantic([], ["field"])
      assert error.field == :queries
    end

    test "rejects non-list queries" do
      assert {:error, error} = Highlighter.semantic("query", ["field"])
      assert error.field == :queries
    end

    test "rejects empty input_fields" do
      assert {:error, error} = Highlighter.semantic(["query"], [])
      assert error.field == :input_fields
    end

    test "rejects non-string elements in queries" do
      assert {:error, error} = Highlighter.semantic([123], ["field"])
      assert error.field == :queries
    end

    test "rejects non-string elements in input_fields" do
      assert {:error, error} = Highlighter.semantic(["query"], [:field])
      assert error.field == :input_fields
    end
  end
end
