defmodule Milvex.Integration.StructArrayTest do
  use Milvex.IntegrationCase, async: false
  @moduletag :integration

  @vector_dim 4

  describe "array of struct schema" do
    test "creates collection with array_of_struct field", %{conn: conn} do
      name = unique_collection_name("struct_array")
      on_exit(fn -> cleanup_collection(conn, name) end)

      struct_fields = [
        Field.varchar("text", 256),
        Field.vector("embedding", @vector_dim)
      ]

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.varchar("title", 256),
            Field.array("sentences", :struct,
              max_capacity: 10,
              struct_schema: struct_fields
            )
          ]
        )

      assert :ok = Milvex.create_collection(conn, name, schema)
      assert {:ok, true} = Milvex.has_collection(conn, name)
    end

    test "describes collection with array_of_struct field", %{conn: conn} do
      name = unique_collection_name("struct_describe")
      on_exit(fn -> cleanup_collection(conn, name) end)

      struct_fields = [
        Field.varchar("text", 256),
        Field.vector("embedding", @vector_dim)
      ]

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.array("sentences", :struct,
              max_capacity: 10,
              struct_schema: struct_fields
            )
          ]
        )

      :ok = Milvex.create_collection(conn, name, schema)

      assert {:ok, info} = Milvex.describe_collection(conn, name)
      assert info.schema.name == name
    end
  end

  describe "data insertion with array of struct" do
    test "inserts rows with array of struct values", %{conn: conn} do
      name = unique_collection_name("struct_insert")
      on_exit(fn -> cleanup_collection(conn, name) end)

      struct_fields = [
        Field.varchar("text", 256),
        Field.vector("embedding", @vector_dim)
      ]

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.array("sentences", :struct,
              max_capacity: 10,
              struct_schema: struct_fields
            )
          ]
        )

      :ok = Milvex.create_collection(conn, name, schema)

      rows = [
        %{
          sentences: [
            %{"text" => "Hello world", "embedding" => random_vector(@vector_dim)},
            %{"text" => "Goodbye", "embedding" => random_vector(@vector_dim)}
          ]
        },
        %{
          sentences: [
            %{"text" => "Another sentence", "embedding" => random_vector(@vector_dim)}
          ]
        }
      ]

      assert {:ok, result} = Milvex.insert(conn, name, rows)
      assert result.insert_count == 2
    end

    test "inserts rows using Data struct", %{conn: conn} do
      name = unique_collection_name("struct_insert_data")
      on_exit(fn -> cleanup_collection(conn, name) end)

      struct_fields = [
        Field.varchar("text", 256),
        Field.vector("embedding", @vector_dim)
      ]

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.array("sentences", :struct,
              max_capacity: 10,
              struct_schema: struct_fields
            )
          ]
        )

      :ok = Milvex.create_collection(conn, name, schema)

      rows = [
        %{
          sentences: [
            %{"text" => "First", "embedding" => random_vector(@vector_dim)}
          ]
        }
      ]

      data = Data.from_rows!(rows, schema)
      assert {:ok, result} = Milvex.insert(conn, name, data)
      assert result.insert_count == 1
    end
  end

  describe "MAX_SIM index and search" do
    test "creates index with MAX_SIM_COSINE on nested vector", %{conn: conn} do
      name = unique_collection_name("struct_maxsim")
      on_exit(fn -> cleanup_collection(conn, name) end)

      struct_fields = [
        Field.varchar("text", 256),
        Field.vector("embedding", @vector_dim)
      ]

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.array("sentences", :struct,
              max_capacity: 10,
              struct_schema: struct_fields
            )
          ]
        )

      :ok = Milvex.create_collection(conn, name, schema)

      index = Index.hnsw("sentences[embedding]", :max_sim_cosine, m: 8)
      assert :ok = Milvex.create_index(conn, name, index)
    end

    test "creates index with MAX_SIM_IP on nested vector", %{conn: conn} do
      name = unique_collection_name("struct_maxsim_ip")
      on_exit(fn -> cleanup_collection(conn, name) end)

      struct_fields = [
        Field.varchar("text", 256),
        Field.vector("embedding", @vector_dim)
      ]

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.array("sentences", :struct,
              max_capacity: 10,
              struct_schema: struct_fields
            )
          ]
        )

      :ok = Milvex.create_collection(conn, name, schema)

      index = Index.hnsw("sentences[embedding]", :max_sim_ip, m: 8)
      assert :ok = Milvex.create_index(conn, name, index)
    end

    test "searches with MAX_SIM_COSINE metric", %{conn: conn} do
      name = unique_collection_name("struct_search")
      on_exit(fn -> cleanup_collection(conn, name) end)

      struct_fields = [
        Field.varchar("text", 256),
        Field.vector("embedding", @vector_dim)
      ]

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.array("sentences", :struct,
              max_capacity: 10,
              struct_schema: struct_fields
            )
          ]
        )

      :ok = Milvex.create_collection(conn, name, schema)

      rows = [
        %{sentences: [%{"text" => "Cat", "embedding" => [1.0, 0.0, 0.0, 0.0]}]},
        %{sentences: [%{"text" => "Dog", "embedding" => [0.0, 1.0, 0.0, 0.0]}]}
      ]

      {:ok, _} = Milvex.insert(conn, name, rows)

      index = Index.hnsw("sentences[embedding]", :max_sim_cosine, m: 8)
      :ok = Milvex.create_index(conn, name, index)
      :ok = Milvex.load_collection(conn, name)

      query_vector = [1.0, 0.0, 0.0, 0.0]

      assert_eventually(
        match?(
          {:ok, %{num_queries: 1, hits: [_ | _]}},
          Milvex.search(conn, name, [query_vector],
            vector_field: "sentences[embedding]",
            top_k: 2
          )
        )
      )
    end

    test "searches with multiple embeddings per struct finds best match", %{conn: conn} do
      name = unique_collection_name("struct_multi_embed")
      on_exit(fn -> cleanup_collection(conn, name) end)

      struct_fields = [
        Field.varchar("text", 256),
        Field.vector("embedding", @vector_dim)
      ]

      schema =
        Schema.build!(
          name: name,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.array("sentences", :struct,
              max_capacity: 10,
              struct_schema: struct_fields
            )
          ]
        )

      :ok = Milvex.create_collection(conn, name, schema)

      rows = [
        %{
          sentences: [
            %{"text" => "First", "embedding" => [1.0, 0.0, 0.0, 0.0]},
            %{"text" => "Second", "embedding" => [0.5, 0.5, 0.0, 0.0]}
          ]
        },
        %{
          sentences: [
            %{"text" => "Third", "embedding" => [0.0, 0.0, 1.0, 0.0]},
            %{"text" => "Fourth", "embedding" => [0.0, 0.0, 0.0, 1.0]}
          ]
        }
      ]

      {:ok, _} = Milvex.insert(conn, name, rows)

      index = Index.hnsw("sentences[embedding]", :max_sim_cosine, m: 8)
      :ok = Milvex.create_index(conn, name, index)
      :ok = Milvex.load_collection(conn, name)

      query_vector = [1.0, 0.0, 0.0, 0.0]

      assert_eventually(fn ->
        case Milvex.search(conn, name, [query_vector],
               vector_field: "sentences[embedding]",
               top_k: 2
             ) do
          {:ok, %{num_queries: 1, hits: hits}} ->
            hits != []

          _ ->
            false
        end
      end)
    end
  end
end
