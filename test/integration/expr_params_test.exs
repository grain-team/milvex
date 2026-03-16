defmodule Milvex.Integration.ExprParamsTest do
  use Milvex.IntegrationCase, async: false

  alias Milvex.AnnSearch
  alias Milvex.Ranker

  @moduletag :integration

  defp movie_schema(name) do
    Schema.build!(
      name: name,
      fields: [
        Field.primary_key("id", :int64, auto_id: false),
        Field.varchar("title", 256),
        Field.varchar("genre", 128),
        Field.scalar("year", :int64),
        Field.vector("embedding", 4)
      ]
    )
  end

  defp movie_rows do
    [
      %{id: 1, title: "The Matrix", genre: "sci-fi", year: 1999, embedding: [1.0, 0.0, 0.0, 0.0]},
      %{id: 2, title: "Inception", genre: "sci-fi", year: 2010, embedding: [0.0, 1.0, 0.0, 0.0]},
      %{
        id: 3,
        title: "Interstellar",
        genre: "sci-fi",
        year: 2014,
        embedding: [0.0, 0.0, 1.0, 0.0]
      },
      %{
        id: 4,
        title: "The Godfather",
        genre: "drama",
        year: 1972,
        embedding: [0.0, 0.0, 0.0, 1.0]
      },
      %{id: 5, title: "Pulp Fiction", genre: "drama", year: 1994, embedding: [0.5, 0.5, 0.0, 0.0]}
    ]
  end

  setup %{conn: conn} do
    name = unique_collection_name("expr_params")
    schema = movie_schema(name)

    :ok = Milvex.create_collection(conn, name, schema)

    :ok =
      Milvex.create_index(conn, name, "embedding",
        index_type: "AUTOINDEX",
        metric_type: "COSINE"
      )

    data = Data.from_rows!(movie_rows(), schema)
    {:ok, _} = Milvex.insert(conn, name, data)
    :ok = Milvex.load_collection(conn, name)

    on_exit(fn -> cleanup_collection(conn, name) end)

    %{collection_name: name, schema: schema}
  end

  describe "search with expr_params" do
    test "filters using template parameters", %{conn: conn, collection_name: name} do
      query_vector = [0.5, 0.5, 0.5, 0.5]

      assert_eventually(fn ->
        with {:ok, result} <-
               Milvex.search(conn, name, [query_vector],
                 vector_field: "embedding",
                 top_k: 10,
                 filter: "year > {min_year}",
                 expr_params: %{"min_year" => 2000},
                 output_fields: ["title", "year"]
               ),
             [hits | _] <- result.hits do
          Enum.all?(hits, fn hit ->
            (hit.fields["year"] || hit.fields[:year]) > 2000
          end) and length(hits) == 2
        else
          _ -> false
        end
      end)
    end

    test "filters with array template parameter", %{conn: conn, collection_name: name} do
      query_vector = [0.5, 0.5, 0.5, 0.5]

      assert_eventually(fn ->
        with {:ok, result} <-
               Milvex.search(conn, name, [query_vector],
                 vector_field: "embedding",
                 top_k: 10,
                 filter: "genre IN {genres}",
                 expr_params: %{"genres" => ["drama"]},
                 output_fields: ["title", "genre"]
               ),
             [hits | _] <- result.hits do
          length(hits) == 2 and
            Enum.all?(hits, fn hit ->
              (hit.fields["genre"] || hit.fields[:genre]) == "drama"
            end)
        else
          _ -> false
        end
      end)
    end
  end

  describe "query with expr_params" do
    test "filters using template parameters", %{conn: conn, collection_name: name} do
      assert_eventually(fn ->
        case Milvex.query(conn, name, "year >= {min_year} AND year <= {max_year}",
               expr_params: %{"min_year" => 1990, "max_year" => 2000},
               output_fields: ["id", "title", "year"],
               limit: 10
             ) do
          {:ok, result} ->
            length(result.rows) == 2 and
              Enum.all?(result.rows, fn row ->
                row[:year] >= 1990 and row[:year] <= 2000
              end)

          _ ->
            false
        end
      end)
    end

    test "filters with IN template parameter", %{conn: conn, collection_name: name} do
      assert_eventually(fn ->
        case Milvex.query(conn, name, "id IN {ids}",
               expr_params: %{"ids" => [1, 4]},
               output_fields: ["id", "title"],
               limit: 10
             ) do
          {:ok, result} ->
            result.rows |> Enum.map(& &1[:id]) |> Enum.sort() == [1, 4]

          _ ->
            false
        end
      end)
    end
  end

  describe "delete with expr_params" do
    test "deletes using template parameters", %{conn: conn, collection_name: name} do
      assert_eventually(fn ->
        case Milvex.delete(conn, name, "year < {cutoff}", expr_params: %{"cutoff" => 1980}) do
          {:ok, %{delete_count: count}} -> count >= 0
          _ -> false
        end
      end)

      assert_eventually(fn ->
        case Milvex.query(conn, name, "id > 0",
               output_fields: ["id", "year"],
               limit: 10
             ) do
          {:ok, result} ->
            Enum.all?(result.rows, fn row -> row[:year] >= 1980 end)

          _ ->
            false
        end
      end)
    end
  end

  describe "hybrid_search with expr_params" do
    test "filters sub-searches using template parameters", %{conn: conn, collection_name: name} do
      {:ok, search} =
        AnnSearch.new("embedding", [[1.0, 0.0, 0.0, 0.0]],
          limit: 10,
          expr: "year > {min_year}",
          expr_params: %{"min_year" => 2000}
        )

      {:ok, ranker} = Ranker.rrf()

      assert_eventually(fn ->
        with {:ok, result} <-
               Milvex.hybrid_search(conn, name, [search], ranker,
                 output_fields: ["title", "year"]
               ),
             [hits | _] <- result.hits do
          Enum.all?(hits, fn hit ->
            (hit.fields["year"] || hit.fields[:year]) > 2000
          end)
        else
          _ -> false
        end
      end)
    end
  end
end
