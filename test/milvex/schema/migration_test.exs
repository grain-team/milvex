defmodule Milvex.Schema.MigrationTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Milvex.Schema
  alias Milvex.Schema.Field
  alias Milvex.Schema.Migration

  setup :verify_on_exit!

  defmodule MoviesCol do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 512, nullable: true, default: "fresh")
        vector(:embedding, 128)
      end
    end

    def index_config, do: []
  end

  describe "verify_schema!/4 - mismatch deduplication" do
    test "field with multiple property changes appears only once in :mismatches" do
      live_schema = %Schema{
        name: "movies",
        fields: [
          %Field{name: "id", data_type: :int64, is_primary_key: true, auto_id: true},
          %Field{
            name: "title",
            data_type: :varchar,
            max_length: 256,
            nullable: false,
            default_value: nil
          },
          %Field{name: "embedding", data_type: :float_vector, dimension: 128}
        ],
        functions: []
      }

      stub(Milvex, :describe_collection, fn _, _, _ -> {:ok, %{schema: live_schema}} end)

      assert {:ok, {:mismatch, diff}} =
               Migration.verify_schema!(:fake_conn, MoviesCol, "movies", strict: false)

      mismatch_names = Enum.map(diff.mismatches, fn {name, _exp, _cur} -> name end)
      assert "title" in mismatch_names
      assert mismatch_names == Enum.uniq(mismatch_names)
      assert Enum.count(mismatch_names, &(&1 == "title")) == 1
    end
  end
end
