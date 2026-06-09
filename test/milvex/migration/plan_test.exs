defmodule Milvex.Migration.PlanTest do
  use ExUnit.Case, async: true

  alias Milvex.Function
  alias Milvex.Index
  alias Milvex.Migration.Operation
  alias Milvex.Migration.Plan
  alias Milvex.Milvus.Proto.Common.KeyValuePair
  alias Milvex.Milvus.Proto.Milvus.IndexDescription
  alias Milvex.Schema
  alias Milvex.Schema.Field

  defmodule MoviesCol do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 128)
      end
    end

    def index_config do
      [Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)]
    end
  end

  defmodule MoviesColWithDescription do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        varchar(:description, 1024, nullable: true)
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColWithRequiredAdd do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        varchar(:category, 64)
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColWithExtraVector do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 128)
        vector(:embedding2, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColTitleLonger do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 512)
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColTitleShorter do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 128)
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColTitleNullable do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256, nullable: true)
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColTitleDefault do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256, default: "untitled")
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColPartitionKey do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256, partition_key: true)
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColClusteringKey do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256, clustering_key: true)
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColEmbedding64 do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 64)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColTitleInt do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        scalar(:title, :int64)
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColAutoIdFalse do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: false)
        varchar(:title, 256)
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColWithIndexHnsw do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 128)
      end
    end

    def index_config do
      [Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)]
    end
  end

  defmodule MoviesColWithIndexHnswM32 do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 128)
      end
    end

    def index_config do
      [Index.hnsw("embedding", :cosine, m: 32, ef_construction: 256)]
    end
  end

  defmodule MoviesColWithIndexHnswL2 do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 128)
      end
    end

    def index_config do
      [Index.hnsw("embedding", :l2, m: 16, ef_construction: 256)]
    end
  end

  defmodule MoviesColWithIndexIvfPq do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 128)
      end
    end

    def index_config do
      [Index.ivf_pq("embedding", :l2, nlist: 1024, m: 8, nbits: 8)]
    end
  end

  defmodule MoviesColWithIndexIvfPqM16 do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 128)
      end
    end

    def index_config do
      [Index.ivf_pq("embedding", :l2, nlist: 1024, m: 16, nbits: 8)]
    end
  end

  defmodule MoviesColTitleDescNew do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256, description: "movie title")
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  defmodule MoviesColWithBM25Function do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:content, 1024, enable_analyzer: true)
        sparse_vector(:sparse)
      end

      functions do
        bm25(:bm25_fn, input: :content, output: :sparse)
      end
    end

    def index_config, do: []
  end

  defp make_field(name, data_type, attrs \\ []) do
    %Field{
      name: to_string(name),
      data_type: data_type,
      dimension: Keyword.get(attrs, :dimension),
      max_length: Keyword.get(attrs, :max_length),
      nullable: Keyword.get(attrs, :nullable, false),
      is_primary_key: Keyword.get(attrs, :is_primary_key, false),
      auto_id: Keyword.get(attrs, :auto_id, false),
      is_partition_key: Keyword.get(attrs, :is_partition_key, false),
      is_clustering_key: Keyword.get(attrs, :is_clustering_key, false),
      default_value: Keyword.get(attrs, :default_value),
      description: Keyword.get(attrs, :description)
    }
  end

  defp default_live_schema(opts \\ []) do
    %Schema{
      name: "movies",
      description: Keyword.get(opts, :description),
      fields: Keyword.get(opts, :fields, default_live_fields()),
      functions: Keyword.get(opts, :functions, [])
    }
  end

  defp default_live_fields do
    [
      make_field(:id, :int64, is_primary_key: true, auto_id: true),
      make_field(:title, :varchar, max_length: 256),
      make_field(:embedding, :float_vector, dimension: 128)
    ]
  end

  defp hnsw_index_description(opts \\ []) do
    %IndexDescription{
      index_name: Keyword.get(opts, :index_name, "embedding_idx"),
      field_name: Keyword.get(opts, :field_name, "embedding"),
      params: [
        %KeyValuePair{key: "index_type", value: Keyword.get(opts, :index_type, "HNSW")},
        %KeyValuePair{key: "metric_type", value: Keyword.get(opts, :metric_type, "COSINE")},
        %KeyValuePair{key: "M", value: to_string(Keyword.get(opts, :m, 16))},
        %KeyValuePair{
          key: "efConstruction",
          value: to_string(Keyword.get(opts, :ef_construction, 256))
        }
      ]
    }
  end

  defp ivf_pq_index_description(opts \\ []) do
    %IndexDescription{
      index_name: Keyword.get(opts, :index_name, "embedding_idx"),
      field_name: Keyword.get(opts, :field_name, "embedding"),
      params: [
        %KeyValuePair{key: "index_type", value: "IVF_PQ"},
        %KeyValuePair{key: "metric_type", value: Keyword.get(opts, :metric_type, "L2")},
        %KeyValuePair{key: "nlist", value: to_string(Keyword.get(opts, :nlist, 1024))},
        %KeyValuePair{key: "m", value: to_string(Keyword.get(opts, :m, 8))},
        %KeyValuePair{key: "nbits", value: to_string(Keyword.get(opts, :nbits, 8))}
      ]
    }
  end

  describe "diff/4 - new collection" do
    test "live_state nil produces create_collection followed by create_index per index_config" do
      %Plan{operations: ops} = Plan.diff(MoviesCol, nil, nil, "2.6.1")

      assert [first | rest] = ops
      assert %Operation{kind: :create_collection, category: :additive} = first
      assert first.collection_name == "movies"
      assert first.payload.schema.name == "movies"

      assert [%Operation{kind: :create_index, category: :additive, payload: %{index: idx}}] = rest
      assert idx.field_name == "embedding"
      assert idx.index_type == :hnsw
    end

    test "applies prefix to collection_name" do
      %Plan{collection_name: name, prefix: prefix} =
        Plan.diff(MoviesCol, "tenant_a_", nil, "2.6.1")

      assert prefix == "tenant_a_"
      assert name == "tenant_a_movies"
    end

    test "no index_config -> only create_collection" do
      %Plan{operations: ops} = Plan.diff(MoviesColWithDescription, nil, nil, "2.6.1")
      assert [%Operation{kind: :create_collection}] = ops
    end
  end

  describe "diff/4 - field add (additive)" do
    test "nullable scalar add produces additive add_field" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColWithDescription, nil, %{schema: live, indexes: []}, "2.6.1")

      assert Enum.any?(ops, fn op ->
               op.kind == :add_field and
                 op.category == :additive and
                 op.payload.field.name == "description"
             end)
    end
  end

  describe "diff/4 - field add (impossible)" do
    test "non-null no-default add -> impossible with reason" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColWithRequiredAdd, nil, %{schema: live, indexes: []}, "2.6.1")

      add =
        Enum.find(ops, fn op ->
          op.kind == :add_field and op.payload.field.name == "category"
        end)

      assert add.category == :impossible
      assert is_binary(add.reason)
      assert String.contains?(add.reason, "nullable")
    end

    test "vector field add -> impossible" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColWithExtraVector, nil, %{schema: live, indexes: []}, "2.6.1")

      add =
        Enum.find(ops, fn op ->
          op.kind == :add_field and op.payload.field.name == "embedding2"
        end)

      assert add.category == :impossible
      assert String.contains?(add.reason, "vector")
    end

    test "primary key add -> impossible" do
      live_no_pk = %Schema{
        name: "movies",
        fields: [
          make_field(:title, :varchar, max_length: 256),
          make_field(:embedding, :float_vector, dimension: 128)
        ]
      }

      %Plan{operations: ops} =
        Plan.diff(MoviesCol, nil, %{schema: live_no_pk, indexes: []}, "2.6.1")

      add =
        Enum.find(ops, fn op ->
          op.kind == :add_field and op.payload.field.name == "id"
        end)

      assert add.category == :impossible
      assert String.contains?(add.reason, "primary")
    end
  end

  describe "diff/4 - field drop" do
    test "milvus 2.6+ -> destructive" do
      live =
        default_live_schema(
          fields: default_live_fields() ++ [make_field(:legacy, :varchar, max_length: 64)]
        )

      %Plan{operations: ops} =
        Plan.diff(MoviesCol, nil, %{schema: live, indexes: []}, "2.6.1")

      drop =
        Enum.find(ops, fn op ->
          op.kind == :drop_field and op.payload.field_name == "legacy"
        end)

      assert drop.category == :destructive
    end

    test "milvus 2.5.x -> impossible (version too old)" do
      live =
        default_live_schema(
          fields: default_live_fields() ++ [make_field(:legacy, :varchar, max_length: 64)]
        )

      %Plan{operations: ops} =
        Plan.diff(MoviesCol, nil, %{schema: live, indexes: []}, "2.5.4")

      drop =
        Enum.find(ops, fn op ->
          op.kind == :drop_field and op.payload.field_name == "legacy"
        end)

      assert drop.category == :impossible
      assert String.contains?(drop.reason, "2.6")
    end
  end

  describe "diff/4 - field property changes" do
    test "varchar max_length increase -> additive alter_field" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColTitleLonger, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and op.payload.field_name == "title"
        end)

      assert alter.category == :additive
      assert alter.payload.changes == %{max_length: [256, 512]}
    end

    test "varchar max_length decrease -> impossible" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColTitleShorter, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and op.payload.field_name == "title"
        end)

      assert alter.category == :impossible
      assert String.contains?(alter.reason, "max_length")
    end

    test "nullable false -> true -> additive alter_field" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColTitleNullable, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and
            op.payload.field_name == "title" and
            Map.has_key?(op.payload.changes, :nullable)
        end)

      assert alter.category == :additive
      assert alter.payload.changes.nullable == [false, true]
    end

    test "nullable true -> false -> impossible" do
      live =
        default_live_schema(
          fields: [
            make_field(:id, :int64, is_primary_key: true, auto_id: true),
            make_field(:title, :varchar, max_length: 256, nullable: true),
            make_field(:embedding, :float_vector, dimension: 128)
          ]
        )

      %Plan{operations: ops} =
        Plan.diff(MoviesCol, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and
            op.payload.field_name == "title" and
            Map.has_key?(op.payload.changes, :nullable)
        end)

      assert alter.category == :impossible
      assert String.contains?(alter.reason, "nullable")
    end

    test "default_value difference -> no alter_field (Milvus sets defaults at creation, not alterable)" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColTitleDefault, nil, %{schema: live, indexes: []}, "2.6.1")

      refute Enum.any?(ops, fn op ->
               op.kind == :alter_field and
                 match?(%{changes: %{default_value: _}}, op.payload)
             end)
    end

    test "field with a DSL default does not perpetually diff against its proto round-trip" do
      expected = Milvex.Collection.to_schema(MoviesColTitleDefault)

      live = %Schema{
        expected
        | fields: Enum.map(expected.fields, &Field.from_proto(Field.to_proto(&1)))
      }

      assert Plan.field_diff(expected, live) == []
    end
  end

  describe "diff/4 - impossible field changes" do
    test "data_type change -> impossible" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColTitleInt, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and op.payload.field_name == "title"
        end)

      assert alter.category == :impossible
      assert String.contains?(alter.reason, "data type")
    end

    test "dimension change on vector -> impossible" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColEmbedding64, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and op.payload.field_name == "embedding"
        end)

      assert alter.category == :impossible
      assert String.contains?(alter.reason, "dimension")
      assert String.contains?(alter.reason, "RenameCollection")
    end

    test "auto_id toggle -> impossible" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColAutoIdFalse, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and op.payload.field_name == "id"
        end)

      assert alter.category == :impossible

      assert String.contains?(alter.reason, "auto_id") or
               String.contains?(alter.reason, "primary key")
    end

    test "is_partition_key toggle -> impossible" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColPartitionKey, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and op.payload.field_name == "title"
        end)

      assert alter.category == :impossible
      assert String.contains?(alter.reason, "partition")
    end

    test "is_clustering_key toggle -> impossible" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColClusteringKey, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and op.payload.field_name == "title"
        end)

      assert alter.category == :impossible
      assert String.contains?(alter.reason, "clustering")
    end
  end

  describe "diff/4 - impossible array field changes" do
    defmodule MoviesColArrayVarchar do
      use Milvex.Collection

      collection do
        name("movies")

        fields do
          primary_key(:id, :int64, auto_id: true)
          array(:tags, :varchar, max_capacity: 100, max_length: 64)
          vector(:embedding, 128)
        end
      end

      def index_config, do: []
    end

    defmodule MoviesColArrayInt64 do
      use Milvex.Collection

      collection do
        name("movies")

        fields do
          primary_key(:id, :int64, auto_id: true)
          array(:tags, :int64, max_capacity: 100)
          vector(:embedding, 128)
        end
      end

      def index_config, do: []
    end

    defmodule MoviesColArrayCap200 do
      use Milvex.Collection

      collection do
        name("movies")

        fields do
          primary_key(:id, :int64, auto_id: true)
          array(:tags, :varchar, max_capacity: 200, max_length: 64)
          vector(:embedding, 128)
        end
      end

      def index_config, do: []
    end

    test "array element_type change -> impossible" do
      live =
        default_live_schema(
          fields: [
            make_field(:id, :int64, is_primary_key: true, auto_id: true),
            %Field{
              name: "tags",
              data_type: :array,
              element_type: :varchar,
              max_capacity: 100,
              max_length: 64
            },
            make_field(:embedding, :float_vector, dimension: 128)
          ]
        )

      %Plan{operations: ops} =
        Plan.diff(MoviesColArrayInt64, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and op.payload.field_name == "tags"
        end)

      assert alter.category == :impossible
      assert String.contains?(alter.reason, "element_type")
    end

    test "array max_capacity change -> impossible" do
      live =
        default_live_schema(
          fields: [
            make_field(:id, :int64, is_primary_key: true, auto_id: true),
            %Field{
              name: "tags",
              data_type: :array,
              element_type: :varchar,
              max_capacity: 100,
              max_length: 64
            },
            make_field(:embedding, :float_vector, dimension: 128)
          ]
        )

      %Plan{operations: ops} =
        Plan.diff(MoviesColArrayCap200, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_field and op.payload.field_name == "tags"
        end)

      assert alter.category == :impossible
      assert String.contains?(alter.reason, "max_capacity")
    end
  end

  describe "diff/4 - index operations" do
    test "missing index in live -> additive create_index" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(MoviesColWithIndexHnsw, nil, %{schema: live, indexes: []}, "2.6.1")

      create =
        Enum.find(ops, fn op ->
          op.kind == :create_index and op.payload.index.field_name == "embedding"
        end)

      assert create.category == :additive
    end

    test "extra index in live -> destructive drop_index" do
      live = default_live_schema()

      live_indexes = [
        %IndexDescription{
          index_name: "stale_idx",
          field_name: "extra_field",
          params: [
            %KeyValuePair{key: "index_type", value: "HNSW"},
            %KeyValuePair{key: "metric_type", value: "COSINE"}
          ]
        }
      ]

      %Plan{operations: ops} =
        Plan.diff(MoviesColWithDescription, nil, %{schema: live, indexes: live_indexes}, "2.6.1")

      drop =
        Enum.find(ops, fn op ->
          op.kind == :drop_index and op.payload.field_name == "extra_field"
        end)

      assert drop.category == :destructive
      assert drop.payload.index_name == "stale_idx"
    end

    test "structural change (M) -> destructive recreate_index" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(
          MoviesColWithIndexHnswM32,
          nil,
          %{schema: live, indexes: [hnsw_index_description(m: 16)]},
          "2.6.1"
        )

      recreate =
        Enum.find(ops, fn op ->
          op.kind == :recreate_index and op.payload.field_name == "embedding"
        end)

      assert recreate.category == :destructive
    end

    test "structural change (efConstruction) -> destructive recreate_index" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(
          MoviesColWithIndexHnsw,
          nil,
          %{schema: live, indexes: [hnsw_index_description(ef_construction: 128)]},
          "2.6.1"
        )

      recreate =
        Enum.find(ops, fn op ->
          op.kind == :recreate_index and op.payload.field_name == "embedding"
        end)

      assert recreate.category == :destructive
    end

    test "metric_type change -> destructive recreate_index" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(
          MoviesColWithIndexHnswL2,
          nil,
          %{schema: live, indexes: [hnsw_index_description(metric_type: "COSINE")]},
          "2.6.1"
        )

      recreate =
        Enum.find(ops, fn op ->
          op.kind == :recreate_index and op.payload.field_name == "embedding"
        end)

      assert recreate.category == :destructive
    end

    test "identical index -> no op" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(
          MoviesColWithIndexHnsw,
          nil,
          %{schema: live, indexes: [hnsw_index_description()]},
          "2.6.1"
        )

      refute Enum.any?(ops, &(&1.kind in [:create_index, :recreate_index, :drop_index]))
    end

    test "IVF_PQ structural change (m) -> destructive recreate_index" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(
          MoviesColWithIndexIvfPqM16,
          nil,
          %{schema: live, indexes: [ivf_pq_index_description(m: 8)]},
          "2.6.1"
        )

      recreate =
        Enum.find(ops, fn op ->
          op.kind == :recreate_index and op.payload.field_name == "embedding"
        end)

      assert recreate.category == :destructive
    end

    test "IVF_PQ structural change (nbits) -> destructive recreate_index" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(
          MoviesColWithIndexIvfPq,
          nil,
          %{schema: live, indexes: [ivf_pq_index_description(nbits: 4)]},
          "2.6.1"
        )

      recreate =
        Enum.find(ops, fn op ->
          op.kind == :recreate_index and op.payload.field_name == "embedding"
        end)

      assert recreate.category == :destructive
    end

    test "IVF_PQ identical params -> no op" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(
          MoviesColWithIndexIvfPq,
          nil,
          %{schema: live, indexes: [ivf_pq_index_description()]},
          "2.6.1"
        )

      refute Enum.any?(ops, &(&1.kind in [:create_index, :recreate_index, :drop_index]))
    end

    test "recreate_index payload old/new have symmetric atom-keyed integer params" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(
          MoviesColWithIndexHnswM32,
          nil,
          %{schema: live, indexes: [hnsw_index_description(m: 16)]},
          "2.6.1"
        )

      recreate =
        Enum.find(ops, fn op ->
          op.kind == :recreate_index and op.payload.field_name == "embedding"
        end)

      assert recreate
      old_params = recreate.payload.old.params
      new_params = recreate.payload.new.params

      assert Map.keys(old_params) |> Enum.sort() == Map.keys(new_params) |> Enum.sort()
      assert Enum.all?(Map.keys(old_params), &is_atom/1)
      assert Enum.all?(Map.keys(new_params), &is_atom/1)
      assert Enum.all?(Map.values(old_params), &is_integer/1)
      assert Enum.all?(Map.values(new_params), &is_integer/1)
      assert old_params[:M] == 16
      assert new_params[:M] == 32
      assert old_params[:efConstruction] == 256
      assert new_params[:efConstruction] == 256

      assert recreate.payload.old.index_type == recreate.payload.new.index_type
    end

    test "recreate_index payload carries the original DSL %Index{} as :dsl_index" do
      live = default_live_schema()

      %Plan{operations: ops} =
        Plan.diff(
          MoviesColWithIndexHnswM32,
          nil,
          %{schema: live, indexes: [hnsw_index_description(m: 16)]},
          "2.6.1"
        )

      recreate =
        Enum.find(ops, fn op ->
          op.kind == :recreate_index and op.payload.field_name == "embedding"
        end)

      assert %Index{
               field_name: "embedding",
               index_type: :hnsw,
               metric_type: :cosine
             } = recreate.payload.dsl_index

      assert recreate.payload.dsl_index.params[:M] == 32
    end
  end

  describe "diff/4 - description-only" do
    test "field description change -> descriptive description_change" do
      live =
        default_live_schema(
          fields: [
            make_field(:id, :int64, is_primary_key: true, auto_id: true),
            make_field(:title, :varchar, max_length: 256, description: "old"),
            make_field(:embedding, :float_vector, dimension: 128)
          ]
        )

      %Plan{operations: ops} =
        Plan.diff(MoviesColTitleDescNew, nil, %{schema: live, indexes: []}, "2.6.1")

      desc =
        Enum.find(ops, fn op ->
          op.kind == :description_change and op.payload.field_name == "title"
        end)

      assert desc.category == :descriptive
      assert desc.payload.from == "old"
      assert desc.payload.to == "movie title"
    end

    test "field description unchanged -> no operation" do
      live =
        default_live_schema(
          fields: [
            make_field(:id, :int64, is_primary_key: true, auto_id: true),
            make_field(:title, :varchar, max_length: 256, description: "movie title"),
            make_field(:embedding, :float_vector, dimension: 128)
          ]
        )

      %Plan{operations: ops} =
        Plan.diff(MoviesColTitleDescNew, nil, %{schema: live, indexes: []}, "2.6.1")

      refute Enum.any?(ops, &(&1.kind == :description_change))
    end
  end

  describe "diff/4 - functions" do
    test "function in DSL missing in live -> additive add_function" do
      live = %Schema{
        name: "movies",
        fields: [
          make_field(:id, :int64, is_primary_key: true, auto_id: true),
          make_field(:content, :varchar, max_length: 1024),
          make_field(:sparse, :sparse_float_vector)
        ],
        functions: []
      }

      %Plan{operations: ops} =
        Plan.diff(MoviesColWithBM25Function, nil, %{schema: live, indexes: []}, "2.6.1")

      add =
        Enum.find(ops, fn op ->
          op.kind == :add_function and op.payload.function.name == "bm25_fn"
        end)

      assert add.category == :additive
    end

    test "function in live missing in DSL -> destructive drop_function" do
      live_fn = Function.new("legacy_fn", :BM25)

      live = %Schema{
        name: "movies",
        fields: default_live_fields(),
        functions: [live_fn]
      }

      %Plan{operations: ops} =
        Plan.diff(MoviesCol, nil, %{schema: live, indexes: []}, "2.6.1")

      drop =
        Enum.find(ops, fn op ->
          op.kind == :drop_function and op.payload.function_name == "legacy_fn"
        end)

      assert drop.category == :destructive
    end

    test "function present in both with different fields -> additive alter_function" do
      live_fn =
        Function.new("bm25_fn", :BM25)
        |> Function.input_field_names(["old_content"])
        |> Function.output_field_names(["old_sparse"])
        |> Function.param("k1", "1.5")

      live = %Schema{
        name: "movies",
        fields: [
          make_field(:id, :int64, is_primary_key: true, auto_id: true),
          make_field(:content, :varchar, max_length: 1024),
          make_field(:sparse, :sparse_float_vector)
        ],
        functions: [live_fn]
      }

      %Plan{operations: ops} =
        Plan.diff(MoviesColWithBM25Function, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_function and op.payload.function_name == "bm25_fn"
        end)

      assert alter
      assert alter.category == :additive
      assert alter.payload.changes.input_field_names == [["old_content"], ["content"]]
      assert alter.payload.changes.output_field_names == [["old_sparse"], ["sparse"]]
      assert alter.payload.changes.params == [%{"k1" => "1.5"}, %{}]
    end

    test "alter_function payload carries the DSL %Function{} as :dsl_function" do
      live_fn =
        Function.new("bm25_fn", :BM25)
        |> Function.input_field_names(["old_content"])
        |> Function.output_field_names(["old_sparse"])

      live = %Schema{
        name: "movies",
        fields: [
          make_field(:id, :int64, is_primary_key: true, auto_id: true),
          make_field(:content, :varchar, max_length: 1024),
          make_field(:sparse, :sparse_float_vector)
        ],
        functions: [live_fn]
      }

      %Plan{operations: ops} =
        Plan.diff(MoviesColWithBM25Function, nil, %{schema: live, indexes: []}, "2.6.1")

      alter =
        Enum.find(ops, fn op ->
          op.kind == :alter_function and op.payload.function_name == "bm25_fn"
        end)

      assert %Function{name: "bm25_fn", type: :BM25} = alter.payload.dsl_function
      assert alter.payload.dsl_function.input_field_names == ["content"]
      assert alter.payload.dsl_function.output_field_names == ["sparse"]
    end
  end

  describe "Plan struct" do
    test "carries module, collection_name, prefix, milvus_version" do
      plan = Plan.diff(MoviesCol, "p_", nil, "2.6.1")
      assert plan.module == MoviesCol
      assert plan.collection_name == "p_movies"
      assert plan.prefix == "p_"
      assert plan.milvus_version == "2.6.1"
      assert is_list(plan.operations)
    end
  end

  describe "field_diff/2" do
    test "returns [] when expected and live schemas are identical" do
      schema = default_live_schema()
      assert Plan.field_diff(schema, schema) == []
    end

    test "field present only in expected -> :add_field op" do
      live = default_live_schema()

      expected = %Schema{
        name: "movies",
        fields:
          default_live_fields() ++
            [make_field(:description, :varchar, max_length: 1024, nullable: true)],
        functions: []
      }

      ops = Plan.field_diff(expected, live)

      assert [%Operation{kind: :add_field} = op] = ops
      assert op.payload.field.name == "description"
    end

    test "field present only in live -> :drop_field op" do
      expected = default_live_schema()

      live = %Schema{
        name: "movies",
        fields: default_live_fields() ++ [make_field(:legacy, :varchar, max_length: 64)],
        functions: []
      }

      ops = Plan.field_diff(expected, live)

      assert [%Operation{kind: :drop_field, payload: %{field_name: "legacy"}}] = ops
    end

    test "field present in both with different max_length -> :alter_field op" do
      expected = %Schema{
        name: "movies",
        fields: [
          make_field(:id, :int64, is_primary_key: true, auto_id: true),
          make_field(:title, :varchar, max_length: 512),
          make_field(:embedding, :float_vector, dimension: 128)
        ],
        functions: []
      }

      live = default_live_schema()

      ops = Plan.field_diff(expected, live)

      assert [%Operation{kind: :alter_field, payload: %{field_name: "title"}}] = ops
    end

    test "ignores description-only changes" do
      expected = %Schema{
        name: "movies",
        fields: [
          make_field(:id, :int64, is_primary_key: true, auto_id: true),
          make_field(:title, :varchar, max_length: 256, description: "fresh"),
          make_field(:embedding, :float_vector, dimension: 128)
        ],
        functions: []
      }

      live =
        default_live_schema(
          fields: [
            make_field(:id, :int64, is_primary_key: true, auto_id: true),
            make_field(:title, :varchar, max_length: 256, description: "stale"),
            make_field(:embedding, :float_vector, dimension: 128)
          ]
        )

      assert Plan.field_diff(expected, live) == []
    end

    test "ignores function differences" do
      expected = %Schema{
        name: "movies",
        fields: default_live_fields(),
        functions: [Function.new("bm25_fn", :BM25)]
      }

      live = default_live_schema()

      assert Plan.field_diff(expected, live) == []
    end

    test "data_type change -> :alter_field op" do
      expected = %Schema{
        name: "movies",
        fields: [
          make_field(:id, :int64, is_primary_key: true, auto_id: true),
          make_field(:title, :int64),
          make_field(:embedding, :float_vector, dimension: 128)
        ],
        functions: []
      }

      live = default_live_schema()

      ops = Plan.field_diff(expected, live)

      assert [%Operation{kind: :alter_field, payload: %{field_name: "title"}} = op] = ops
      assert op.category == :impossible
    end
  end
end
