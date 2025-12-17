defmodule Milvex.Integration.DataTest do
  use Milvex.IntegrationCase, async: false

  @moduletag :integration

  describe "insert/4" do
    test "inserts data with Data struct", %{conn: conn} do
      name = unique_collection_name("insert_data")
      schema = standard_schema(name)

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      data = sample_data(schema, 3)
      assert {:ok, result} = Milvex.insert(conn, name, data)
      assert result.insert_count == 3
      assert length(result.ids) == 3
    end

    test "inserts data with row maps", %{conn: conn} do
      name = unique_collection_name("insert_rows")
      schema = standard_schema(name)

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      rows = sample_rows(3)
      assert {:ok, result} = Milvex.insert(conn, name, rows)
      assert result.insert_count == 3
      assert length(result.ids) == 3
    end

    test "generates IDs when auto_id is true", %{conn: conn} do
      name = unique_collection_name("insert_autoid")
      schema = standard_schema(name, auto_id: true)

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      data = sample_data(schema, 3)
      assert {:ok, result} = Milvex.insert(conn, name, data)

      assert length(result.ids) == 3
      assert Enum.all?(result.ids, &is_integer/1)
    end

    test "accepts manual IDs when auto_id is false", %{conn: conn} do
      name = unique_collection_name("insert_manual")
      schema = manual_id_schema(name)

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      rows = sample_rows_with_ids(3, start_id: 100)
      data = Data.from_rows!(rows, schema)

      assert {:ok, result} = Milvex.insert(conn, name, data)
      assert result.insert_count == 3
      assert 100 in result.ids
      assert 101 in result.ids
      assert 102 in result.ids
    end

    test "inserts into specific partition", %{conn: conn} do
      name = unique_collection_name("insert_partition")
      schema = standard_schema(name)
      partition = "test_partition"

      on_exit(fn ->
        cleanup_partition(conn, name, partition)
        cleanup_collection(conn, name)
      end)

      :ok = Milvex.create_collection(conn, name, schema)
      :ok = Milvex.create_partition(conn, name, partition)

      data = sample_data(schema, 3)
      assert {:ok, result} = Milvex.insert(conn, name, data, partition_name: partition)
      assert result.insert_count == 3
    end

    test "fails for non-existent collection", %{conn: conn} do
      name = unique_collection_name("insert_nonexistent")
      schema = standard_schema(name)

      data = sample_data(schema, 3)
      assert {:error, error} = Milvex.insert(conn, name, data)
      assert %Milvex.Errors.Grpc{} = error
    end

    test "fails with wrong dimension vectors", %{conn: conn} do
      name = unique_collection_name("insert_wrong_dim")
      schema = standard_schema(name, dimension: 4)

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      wrong_dim_rows = [
        %{title: "Test", embedding: [0.1, 0.2]}
      ]

      assert {:error, _error} = Milvex.insert(conn, name, wrong_dim_rows)
    end
  end

  describe "delete/4" do
    test "deletes by id expression", %{conn: conn} do
      name = unique_collection_name("delete_by_id")
      schema = manual_id_schema(name)

      on_exit(fn -> cleanup_collection(conn, name) end)

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

      assert {:ok, result} = Milvex.delete(conn, name, "id in [1, 2, 3]")
      assert result.delete_count == 3
    end

    test "deletes with filter expression", %{conn: conn} do
      name = unique_collection_name("delete_filter")
      schema = manual_id_schema(name)

      on_exit(fn -> cleanup_collection(conn, name) end)

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

      assert {:ok, result} = Milvex.delete(conn, name, "id >= 3")
      assert result.delete_count == 3
    end

    test "fails for non-existent collection", %{conn: conn} do
      name = unique_collection_name("delete_nonexistent")

      assert {:error, error} = Milvex.delete(conn, name, "id > 0")
      assert %Milvex.Errors.Grpc{} = error
    end

    test "fails with invalid expression", %{conn: conn} do
      name = unique_collection_name("delete_invalid")
      schema = standard_schema(name)

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      :ok =
        Milvex.create_index(conn, name, "embedding",
          index_type: "AUTOINDEX",
          metric_type: "COSINE"
        )

      :ok = Milvex.load_collection(conn, name)

      assert {:error, error} = Milvex.delete(conn, name, "invalid syntax !!!")
      assert %Milvex.Errors.Grpc{} = error
    end
  end

  describe "upsert/4" do
    test "inserts new records", %{conn: conn} do
      name = unique_collection_name("upsert_insert")
      schema = manual_id_schema(name)

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      rows = sample_rows_with_ids(3, start_id: 1)
      data = Data.from_rows!(rows, schema)

      assert {:ok, result} = Milvex.upsert(conn, name, data)
      assert result.upsert_count == 3
      assert length(result.ids) == 3
    end

    test "updates existing records", %{conn: conn} do
      name = unique_collection_name("upsert_update")
      schema = manual_id_schema(name)

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      :ok =
        Milvex.create_index(conn, name, "embedding",
          index_type: "AUTOINDEX",
          metric_type: "COSINE"
        )

      initial_rows = sample_rows_with_ids(3, start_id: 1)
      initial_data = Data.from_rows!(initial_rows, schema)
      {:ok, _} = Milvex.insert(conn, name, initial_data)

      :ok = Milvex.load_collection(conn, name)

      updated_rows = [
        %{id: 1, title: "Updated Item 1", embedding: random_vector(4)},
        %{id: 2, title: "Updated Item 2", embedding: random_vector(4)},
        %{id: 4, title: "New Item 4", embedding: random_vector(4)}
      ]

      updated_data = Data.from_rows!(updated_rows, schema)

      assert {:ok, result} = Milvex.upsert(conn, name, updated_data)
      assert result.upsert_count == 3

      assert_eventually(
        match?(
          {:ok, %{rows: rows}} when length(rows) == 4,
          Milvex.query(conn, name, "id >= 0", output_fields: ["id", "title"], limit: 10)
        )
      )
    end

    test "fails for non-existent collection", %{conn: conn} do
      name = unique_collection_name("upsert_nonexistent")
      schema = manual_id_schema(name)

      rows = sample_rows_with_ids(3)
      data = Data.from_rows!(rows, schema)

      assert {:error, error} = Milvex.upsert(conn, name, data)
      assert %Milvex.Errors.Grpc{} = error
    end
  end

  describe "insert with dynamic fields" do
    test "inserts rows with dynamic fields", %{conn: conn} do
      name = unique_collection_name("insert_dynamic")

      schema =
        Schema.build!(
          name: name,
          enable_dynamic_field: true,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.varchar("title", 256),
            Field.vector("embedding", 4)
          ]
        )

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      rows = [
        %{title: "Item 1", embedding: random_vector(4), category: "books", rating: 4.5},
        %{title: "Item 2", embedding: random_vector(4), category: "movies", rating: 3.0}
      ]

      assert {:ok, result} = Milvex.insert(conn, name, rows)
      assert result.insert_count == 2
    end

    test "queries dynamic fields after insert", %{conn: conn} do
      name = unique_collection_name("query_dynamic")

      schema =
        Schema.build!(
          name: name,
          enable_dynamic_field: true,
          fields: [
            Field.primary_key("id", :int64, auto_id: false),
            Field.varchar("title", 256),
            Field.vector("embedding", 4)
          ]
        )

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      :ok =
        Milvex.create_index(conn, name, "embedding",
          index_type: "AUTOINDEX",
          metric_type: "COSINE"
        )

      rows = [
        %{id: 1, title: "Item 1", embedding: random_vector(4), category: "books"},
        %{id: 2, title: "Item 2", embedding: random_vector(4), category: "movies"}
      ]

      {:ok, _} = Milvex.insert(conn, name, rows)
      :ok = Milvex.load_collection(conn, name)

      assert_eventually(
        match?(
          {:ok, %{rows: [%{"$meta" => %{"category" => "books"}} | _]}},
          Milvex.query(conn, name, "id == 1", output_fields: ["title", "category"])
        )
      )
    end

    test "filters by dynamic fields in query", %{conn: conn} do
      name = unique_collection_name("filter_dynamic")

      schema =
        Schema.build!(
          name: name,
          enable_dynamic_field: true,
          fields: [
            Field.primary_key("id", :int64, auto_id: false),
            Field.varchar("title", 256),
            Field.vector("embedding", 4)
          ]
        )

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      :ok =
        Milvex.create_index(conn, name, "embedding",
          index_type: "AUTOINDEX",
          metric_type: "COSINE"
        )

      rows = [
        %{id: 1, title: "Book 1", embedding: random_vector(4), category: "books", rating: 4.5},
        %{id: 2, title: "Movie 1", embedding: random_vector(4), category: "movies", rating: 3.0},
        %{id: 3, title: "Book 2", embedding: random_vector(4), category: "books", rating: 5.0}
      ]

      {:ok, _} = Milvex.insert(conn, name, rows)
      :ok = Milvex.load_collection(conn, name)

      assert_eventually(fn ->
        case Milvex.query(conn, name, "category == \"books\"",
               output_fields: ["title", "category", "rating"]
             ) do
          {:ok, %{rows: result_rows}} when length(result_rows) == 2 ->
            result_rows
            |> Enum.all?(fn row ->
              row["$meta"]["category"] == "books" and
                row["title"] in ["Book 1", "Book 2"] and
                row["$meta"]["rating"] in [4.5, 5.0]
            end)

          _ ->
            false
        end
      end)
    end

    test "searches with dynamic field filter", %{conn: conn} do
      name = unique_collection_name("search_dynamic")

      schema =
        Schema.build!(
          name: name,
          enable_dynamic_field: true,
          fields: [
            Field.primary_key("id", :int64, auto_id: false),
            Field.varchar("title", 256),
            Field.vector("embedding", 4)
          ]
        )

      on_exit(fn -> cleanup_collection(conn, name) end)

      :ok = Milvex.create_collection(conn, name, schema)

      :ok =
        Milvex.create_index(conn, name, "embedding",
          index_type: "AUTOINDEX",
          metric_type: "COSINE"
        )

      rows = [
        %{id: 1, title: "Item 1", embedding: [1.0, 0.0, 0.0, 0.0], category: "A"},
        %{id: 2, title: "Item 2", embedding: [0.9, 0.1, 0.0, 0.0], category: "A"},
        %{id: 3, title: "Item 3", embedding: [0.8, 0.2, 0.0, 0.0], category: "B"}
      ]

      {:ok, _} = Milvex.insert(conn, name, rows)
      :ok = Milvex.load_collection(conn, name)

      query_vector = [1.0, 0.0, 0.0, 0.0]

      assert_eventually(fn ->
        case Milvex.search(conn, name, [query_vector],
               vector_field: "embedding",
               top_k: 10,
               filter: "category == \"A\"",
               output_fields: ["title", "category"]
             ) do
          {:ok, %{hits: [result_hits | _]}} when length(result_hits) == 2 ->
            result_hits
            |> Enum.all?(fn hit ->
              hit.fields["$meta"]["category"] == "A" and
                hit.fields["title"] in ["Item 1", "Item 2"] and
                is_float(hit.distance) and
                is_integer(hit.id)
            end)

          _ ->
            false
        end
      end)
    end
  end
end
