defmodule Milvex.Integration.HighlightTest do
  @moduledoc """
  Integration tests for search result highlighting.

  Highlighting requires Milvus 2.6.8+ with BM25 full-text search.
  The highlighted field must have enable_analyzer: true, and the
  output_fields must include the field being highlighted.
  """
  use Milvex.IntegrationCase

  alias Milvex.AnnSearch
  alias Milvex.Function
  alias Milvex.Highlighter
  alias Milvex.Index
  alias Milvex.Ranker
  alias Milvex.Schema
  alias Milvex.Schema.Field

  @moduletag :integration
  @collection_name "highlight_test"

  setup %{conn: conn} do
    on_exit(fn ->
      Milvex.drop_collection(conn, @collection_name)
    end)

    schema =
      Schema.build!(
        name: @collection_name,
        fields: [
          Field.primary_key("id", :int64, auto_id: true),
          Field.varchar("content", 2048, enable_analyzer: true),
          Field.sparse_vector("sparse")
        ]
      )
      |> Schema.add_function(Function.bm25("bm25_fn", input: "content", output: "sparse"))

    :ok = Milvex.create_collection(conn, @collection_name, schema)
    :ok = Milvex.create_index(conn, @collection_name, Index.sparse_bm25("sparse"))
    :ok = Milvex.load_collection(conn, @collection_name)

    data = [
      %{content: "Artificial intelligence is transforming the world of technology"},
      %{content: "Machine learning algorithms power modern AI systems"},
      %{content: "Deep learning neural networks achieve remarkable results"},
      %{content: "Natural language processing enables text understanding"},
      %{content: "Computer vision allows machines to interpret images"}
    ]

    {:ok, _} = Milvex.insert(conn, @collection_name, data)

    {:ok, conn: conn}
  end

  describe "highlight with BM25 search" do
    test "returns non-empty highlights for matching terms", %{conn: conn} do
      {:ok, highlighter} = Highlighter.lexical("content")

      {:ok, result} =
        Milvex.search(conn, @collection_name, ["machine learning"],
          vector_field: "sparse",
          metric_type: "BM25",
          top_k: 3,
          output_fields: ["content"],
          consistency_level: :Strong,
          highlight: highlighter
        )

      hits = List.flatten(result.hits)
      assert [_ | _] = hits

      for hit <- hits do
        assert hit.highlights != %{}, "expected non-empty highlights when highlighting is enabled"
        assert Map.has_key?(hit.highlights, "content")
        assert [_ | _] = hit.highlights["content"]
      end
    end

    test "uses custom pre/post tags in highlighted fragments", %{conn: conn} do
      {:ok, highlighter} = Highlighter.lexical("content", pre_tag: "<em>", post_tag: "</em>")

      {:ok, result} =
        Milvex.search(conn, @collection_name, ["artificial intelligence"],
          vector_field: "sparse",
          metric_type: "BM25",
          top_k: 3,
          output_fields: ["content"],
          consistency_level: :Strong,
          highlight: highlighter
        )

      hits = List.flatten(result.hits)
      assert [_ | _] = hits

      for hit <- hits do
        assert hit.highlights != %{}, "expected non-empty highlights with custom tags"
        assert [_ | _] = fragments = hit.highlights["content"]

        for fragment <- fragments do
          assert String.contains?(fragment, "<em>") or String.contains?(fragment, "</em>"),
                 "expected custom <em> tags in fragment: #{fragment}"
        end
      end
    end

    test "without highlight option returns empty highlights", %{conn: conn} do
      {:ok, result} =
        Milvex.search(conn, @collection_name, ["machine learning"],
          vector_field: "sparse",
          metric_type: "BM25",
          top_k: 3,
          output_fields: ["content"],
          consistency_level: :Strong
        )

      hits = List.flatten(result.hits)
      assert [_ | _] = hits

      for hit <- hits do
        assert hit.highlights == %{}
      end
    end

    test "default tags use <b> in highlighted fragments", %{conn: conn} do
      {:ok, highlighter} = Highlighter.lexical("content")

      {:ok, result} =
        Milvex.search(conn, @collection_name, ["learning algorithms"],
          vector_field: "sparse",
          metric_type: "BM25",
          top_k: 3,
          output_fields: ["content"],
          consistency_level: :Strong,
          highlight: highlighter
        )

      hits = List.flatten(result.hits)
      assert [_ | _] = hits

      for hit <- hits do
        assert hit.highlights != %{}, "expected non-empty highlights with default tags"
        fragments = hit.highlights["content"]

        for fragment <- fragments do
          assert String.contains?(fragment, "<b>") or String.contains?(fragment, "</b>"),
                 "expected default <b> tags in fragment: #{fragment}"
        end
      end
    end

    @tag :skip
    @tag :zilliz
    test "semantic highlighter returns highlights (requires Zilliz Cloud)", %{conn: conn} do
      {:ok, highlighter} = Highlighter.semantic(["machine learning"], ["content"])

      {:ok, result} =
        Milvex.search(conn, @collection_name, ["machine learning"],
          vector_field: "sparse",
          metric_type: "BM25",
          top_k: 3,
          output_fields: ["content"],
          consistency_level: :Strong,
          highlight: highlighter
        )

      hits = List.flatten(result.hits)
      assert [_ | _] = hits

      for hit <- hits do
        assert hit.highlights != %{}, "expected non-empty highlights with semantic highlighter"
        assert Map.has_key?(hit.highlights, "content")
        assert [_ | _] = hit.highlights["content"]
      end
    end

    test "hybrid_search does not support highlighting", %{conn: conn} do
      {:ok, search} = AnnSearch.new("sparse", ["machine learning"], limit: 3)
      {:ok, ranker} = Ranker.rrf()

      {:ok, result} =
        Milvex.hybrid_search(conn, @collection_name, [search], ranker,
          output_fields: ["content"],
          limit: 3,
          consistency_level: :Strong
        )

      hits = List.flatten(result.hits)
      assert [_ | _] = hits

      for hit <- hits do
        assert hit.highlights == %{}
      end
    end
  end
end
