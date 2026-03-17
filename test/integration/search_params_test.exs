defmodule Milvex.Integration.SearchParamsTest do
  use Milvex.IntegrationCase, async: false

  alias Milvex.AnnSearch
  alias Milvex.Ranker

  @moduletag :integration

  defp ids_disjoint?(h1, h2) do
    MapSet.disjoint?(MapSet.new(h1, & &1.id), MapSet.new(h2, & &1.id))
  end

  defp unique_categories(hits) do
    hits
    |> Enum.map(&(Map.get(&1.fields, "category") || Map.get(&1.fields, :category)))
    |> Enum.uniq()
  end

  describe "search with offset" do
    setup %{conn: conn} do
      name = unique_collection_name("search_offset")
      schema = manual_id_schema(name)

      :ok = Milvex.create_collection(conn, name, schema)

      :ok =
        Milvex.create_index(conn, name, "embedding",
          index_type: "AUTOINDEX",
          metric_type: "COSINE"
        )

      rows = sample_rows_with_ids(10, start_id: 1)
      data = Data.from_rows!(rows, schema)
      {:ok, _} = Milvex.insert(conn, name, data)
      :ok = Milvex.load_collection(conn, name)

      on_exit(fn -> cleanup_collection(conn, name) end)

      %{collection_name: name, schema: schema}
    end

    test "offset skips results without overlap", %{conn: conn, collection_name: name} do
      query_vector = [1.0, 0.0, 0.0, 0.0]

      assert_eventually(fn ->
        case {
          Milvex.search(conn, name, [query_vector], vector_field: "embedding", top_k: 3),
          Milvex.search(conn, name, [query_vector],
            vector_field: "embedding",
            top_k: 3,
            offset: 3
          )
        } do
          {{:ok, %{hits: [[_ | _] = h1 | _]}}, {:ok, %{hits: [[_ | _] = h2 | _]}}} ->
            ids_disjoint?(h1, h2)

          _ ->
            false
        end
      end)
    end

    test "offset near end returns fewer results", %{conn: conn} do
      name = unique_collection_name("search_offset_end")
      schema = manual_id_schema(name)

      :ok = Milvex.create_collection(conn, name, schema)

      :ok =
        Milvex.create_index(conn, name, "embedding",
          index_type: "AUTOINDEX",
          metric_type: "COSINE"
        )

      rows = sample_rows_with_ids(5, start_id: 1)
      data = Data.from_rows!(rows, schema)
      {:ok, _} = Milvex.insert(conn, name, data)
      :ok = Milvex.load_collection(conn, name)

      on_exit(fn -> cleanup_collection(conn, name) end)

      query_vector = [1.0, 0.0, 0.0, 0.0]

      assert_eventually(fn ->
        case Milvex.search(conn, name, [query_vector],
               vector_field: "embedding",
               top_k: 10,
               offset: 3
             ) do
          {:ok, %{hits: [hits | _]}} -> length(hits) <= 2
          _ -> false
        end
      end)
    end
  end

  describe "search with grouping" do
    setup %{conn: conn} do
      name = unique_collection_name("search_group")

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: false),
            Field.varchar("title", 256),
            Field.varchar("category", 64),
            Field.vector("embedding", 4)
          ]
        )

      :ok = Milvex.create_collection(conn, name, schema)

      :ok =
        Milvex.create_index(conn, name, "embedding",
          index_type: "AUTOINDEX",
          metric_type: "COSINE"
        )

      rows = [
        %{id: 1, title: "A1", category: "electronics", embedding: [1.0, 0.0, 0.0, 0.0]},
        %{id: 2, title: "A2", category: "electronics", embedding: [0.9, 0.1, 0.0, 0.0]},
        %{id: 3, title: "B1", category: "clothing", embedding: [0.0, 1.0, 0.0, 0.0]},
        %{id: 4, title: "B2", category: "clothing", embedding: [0.0, 0.9, 0.1, 0.0]},
        %{id: 5, title: "C1", category: "food", embedding: [0.0, 0.0, 1.0, 0.0]},
        %{id: 6, title: "C2", category: "food", embedding: [0.0, 0.0, 0.9, 0.1]}
      ]

      data = Data.from_rows!(rows, schema)
      {:ok, _} = Milvex.insert(conn, name, data)
      :ok = Milvex.load_collection(conn, name)

      on_exit(fn -> cleanup_collection(conn, name) end)

      %{collection_name: name, schema: schema}
    end

    test "group_by_field groups results by category", %{conn: conn, collection_name: name} do
      query_vector = [0.5, 0.5, 0.5, 0.0]

      assert_eventually(fn ->
        case Milvex.search(conn, name, [query_vector],
               vector_field: "embedding",
               top_k: 3,
               group_by_field: "category",
               output_fields: ["category"]
             ) do
          {:ok, %{hits: [[_ | _] = hits | _]}} ->
            length(unique_categories(hits)) == length(hits) and
              length(unique_categories(hits)) <= 3

          _ ->
            false
        end
      end)
    end

    test "group_size returns multiple results per group", %{
      conn: conn,
      collection_name: name
    } do
      query_vector = [0.5, 0.5, 0.5, 0.0]

      assert_eventually(fn ->
        case Milvex.search(conn, name, [query_vector],
               vector_field: "embedding",
               top_k: 3,
               group_by_field: "category",
               group_size: 2,
               output_fields: ["category"]
             ) do
          {:ok, %{hits: [[_ | _] | _]}} -> true
          _ -> false
        end
      end)
    end
  end

  describe "search misc params" do
    setup %{conn: conn} do
      name = unique_collection_name("search_misc")
      schema = standard_schema(name)

      :ok = Milvex.create_collection(conn, name, schema)

      :ok =
        Milvex.create_index(conn, name, "embedding",
          index_type: "AUTOINDEX",
          metric_type: "COSINE"
        )

      rows = sample_rows(5)
      data = Data.from_rows!(rows, schema)
      {:ok, _} = Milvex.insert(conn, name, data)
      :ok = Milvex.load_collection(conn, name)

      on_exit(fn -> cleanup_collection(conn, name) end)

      %{collection_name: name, schema: schema}
    end

    test "round_decimal rounds scores", %{conn: conn, collection_name: name} do
      query_vector = random_vector(4)

      assert_eventually(fn ->
        case Milvex.search(conn, name, [query_vector],
               vector_field: "embedding",
               top_k: 3,
               round_decimal: 2
             ) do
          {:ok, %{hits: [[_ | _] = hits | _]}} ->
            Enum.all?(hits, &(abs(&1.score - Float.round(&1.score * 100) / 100) < 0.001))

          _ ->
            false
        end
      end)
    end

    test "ignore_growing succeeds", %{conn: conn, collection_name: name} do
      query_vector = random_vector(4)

      assert_eventually(
        match?(
          {:ok, %{num_queries: 1}},
          Milvex.search(conn, name, [query_vector],
            vector_field: "embedding",
            top_k: 3,
            ignore_growing: true
          )
        )
      )
    end
  end

  describe "hybrid_search with offset" do
    setup %{conn: conn} do
      name = unique_collection_name("hybrid_offset")

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.varchar("title", 256),
            Field.vector("text_embedding", 4),
            Field.vector("image_embedding", 4)
          ]
        )

      :ok = Milvex.create_collection(conn, name, schema)
      :ok = Milvex.create_index(conn, name, Index.autoindex("text_embedding", :cosine))
      :ok = Milvex.create_index(conn, name, Index.autoindex("image_embedding", :cosine))
      :ok = Milvex.load_collection(conn, name)

      data = [
        %{
          title: "Item 1",
          text_embedding: [1.0, 0.0, 0.0, 0.0],
          image_embedding: [0.0, 1.0, 0.0, 0.0]
        },
        %{
          title: "Item 2",
          text_embedding: [0.0, 1.0, 0.0, 0.0],
          image_embedding: [0.0, 0.0, 1.0, 0.0]
        },
        %{
          title: "Item 3",
          text_embedding: [0.0, 0.0, 1.0, 0.0],
          image_embedding: [1.0, 0.0, 0.0, 0.0]
        }
      ]

      {:ok, _} = Milvex.insert(conn, name, data)
      Process.sleep(1000)

      on_exit(fn -> cleanup_collection(conn, name) end)

      %{collection_name: name}
    end

    test "hybrid_search with offset returns results", %{conn: conn, collection_name: name} do
      {:ok, text_search} = AnnSearch.new("text_embedding", [[1.0, 0.0, 0.0, 0.0]], limit: 3)
      {:ok, image_search} = AnnSearch.new("image_embedding", [[0.0, 1.0, 0.0, 0.0]], limit: 3)
      {:ok, ranker} = Ranker.rrf()

      assert_eventually(fn ->
        case Milvex.hybrid_search(conn, name, [text_search, image_search], ranker,
               output_fields: ["title"],
               limit: 1,
               offset: 1
             ) do
          {:ok, %{hits: hits}} -> not Enum.empty?(hits)
          _ -> false
        end
      end)
    end
  end

  describe "hybrid_search with grouping" do
    setup %{conn: conn} do
      name = unique_collection_name("hybrid_group")

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: false),
            Field.varchar("title", 256),
            Field.varchar("category", 64),
            Field.vector("text_embedding", 4),
            Field.vector("image_embedding", 4)
          ]
        )

      :ok = Milvex.create_collection(conn, name, schema)
      :ok = Milvex.create_index(conn, name, Index.autoindex("text_embedding", :cosine))
      :ok = Milvex.create_index(conn, name, Index.autoindex("image_embedding", :cosine))
      :ok = Milvex.load_collection(conn, name)

      data = [
        %{
          id: 1,
          title: "A1",
          category: "electronics",
          text_embedding: [1.0, 0.0, 0.0, 0.0],
          image_embedding: [0.0, 1.0, 0.0, 0.0]
        },
        %{
          id: 2,
          title: "A2",
          category: "electronics",
          text_embedding: [0.9, 0.1, 0.0, 0.0],
          image_embedding: [0.0, 0.9, 0.1, 0.0]
        },
        %{
          id: 3,
          title: "B1",
          category: "clothing",
          text_embedding: [0.0, 1.0, 0.0, 0.0],
          image_embedding: [0.0, 0.0, 1.0, 0.0]
        },
        %{
          id: 4,
          title: "B2",
          category: "clothing",
          text_embedding: [0.0, 0.9, 0.1, 0.0],
          image_embedding: [0.0, 0.0, 0.9, 0.1]
        },
        %{
          id: 5,
          title: "C1",
          category: "food",
          text_embedding: [0.0, 0.0, 1.0, 0.0],
          image_embedding: [1.0, 0.0, 0.0, 0.0]
        },
        %{
          id: 6,
          title: "C2",
          category: "food",
          text_embedding: [0.0, 0.0, 0.9, 0.1],
          image_embedding: [0.9, 0.0, 0.0, 0.1]
        }
      ]

      {:ok, _} = Milvex.insert(conn, name, data)
      Process.sleep(1000)

      on_exit(fn -> cleanup_collection(conn, name) end)

      %{collection_name: name}
    end

    test "hybrid_search with group_by_field groups results", %{
      conn: conn,
      collection_name: name
    } do
      {:ok, text_search} = AnnSearch.new("text_embedding", [[0.5, 0.5, 0.5, 0.0]], limit: 6)
      {:ok, image_search} = AnnSearch.new("image_embedding", [[0.5, 0.5, 0.5, 0.0]], limit: 6)
      {:ok, ranker} = Ranker.rrf()

      assert_eventually(fn ->
        case Milvex.hybrid_search(conn, name, [text_search, image_search], ranker,
               output_fields: ["category"],
               limit: 3,
               group_by_field: "category"
             ) do
          {:ok, %{hits: hits}} -> not Enum.empty?(hits)
          _ -> false
        end
      end)
    end
  end
end
