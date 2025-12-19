defmodule Milvex.SchemaTest do
  use ExUnit.Case, async: true

  alias Milvex.Milvus.Proto.Schema.CollectionSchema
  alias Milvex.Schema
  alias Milvex.Schema.Field

  describe "new/1" do
    test "creates a schema with name" do
      schema = Schema.new("movies")
      assert schema.name == "movies"
      assert schema.fields == []
      assert schema.enable_dynamic_field == false
    end

    test "accepts atom names" do
      schema = Schema.new(:movies)
      assert schema.name == "movies"
    end
  end

  describe "builder methods" do
    test "description/2 sets description" do
      schema = Schema.new("movies") |> Schema.description("Movie embeddings")
      assert schema.description == "Movie embeddings"
    end

    test "add_field/2 adds a single field" do
      field = Field.primary_key("id", :int64)
      schema = Schema.new("movies") |> Schema.add_field(field)
      assert length(schema.fields) == 1
      assert hd(schema.fields).name == "id"
    end

    test "add_field/2 appends fields in order" do
      schema =
        Schema.new("movies")
        |> Schema.add_field(Field.primary_key("id", :int64))
        |> Schema.add_field(Field.varchar("title", 256))
        |> Schema.add_field(Field.vector("embedding", 128))

      assert length(schema.fields) == 3
      assert Enum.map(schema.fields, & &1.name) == ["id", "title", "embedding"]
    end

    test "add_fields/2 adds multiple fields at once" do
      fields = [
        Field.primary_key("id", :int64),
        Field.varchar("title", 256)
      ]

      schema = Schema.new("movies") |> Schema.add_fields(fields)
      assert length(schema.fields) == 2
    end

    test "enable_dynamic_field/2 enables dynamic fields" do
      schema = Schema.new("movies") |> Schema.enable_dynamic_field()
      assert schema.enable_dynamic_field == true
    end

    test "enable_dynamic_field/2 accepts boolean argument" do
      schema = Schema.new("movies") |> Schema.enable_dynamic_field(false)
      assert schema.enable_dynamic_field == false
    end
  end

  describe "build/1" do
    test "builds schema from keyword list" do
      {:ok, schema} =
        Schema.build(
          name: "movies",
          fields: [
            Field.primary_key("id", :int64),
            Field.vector("embedding", 128)
          ]
        )

      assert schema.name == "movies"
      assert length(schema.fields) == 2
    end

    test "builds schema from map" do
      {:ok, schema} =
        Schema.build(%{
          name: "movies",
          fields: [Field.primary_key("id", :int64), Field.vector("embedding", 128)]
        })

      assert schema.name == "movies"
    end

    test "includes optional description" do
      {:ok, schema} =
        Schema.build(
          name: "movies",
          description: "Movie collection",
          fields: [Field.primary_key("id", :int64), Field.vector("embedding", 128)]
        )

      assert schema.description == "Movie collection"
    end

    test "includes enable_dynamic_field option" do
      {:ok, schema} =
        Schema.build(
          name: "movies",
          enable_dynamic_field: true,
          fields: [Field.primary_key("id", :int64), Field.vector("embedding", 128)]
        )

      assert schema.enable_dynamic_field == true
    end

    test "returns error when name is missing" do
      {:error, error} = Schema.build(fields: [Field.primary_key("id", :int64)])
      assert error.field == :name
    end

    test "returns error when fields are missing" do
      {:error, error} = Schema.build(name: "movies")
      assert error.field == :fields
    end

    test "validates the schema" do
      {:error, error} =
        Schema.build(
          name: "movies",
          fields: [Field.vector("embedding", 128)]
        )

      assert error.field == :primary_key
    end
  end

  describe "build!/1" do
    test "returns schema when valid" do
      schema =
        Schema.build!(
          name: "movies",
          fields: [Field.primary_key("id", :int64), Field.vector("embedding", 128)]
        )

      assert schema.name == "movies"
    end

    test "raises when invalid" do
      assert_raise Milvex.Errors.Invalid, fn ->
        Schema.build!(name: "movies", fields: [])
      end
    end
  end

  describe "validate/1" do
    setup do
      valid_schema =
        Schema.new("movies")
        |> Schema.add_field(Field.primary_key("id", :int64))
        |> Schema.add_field(Field.vector("embedding", 128))

      {:ok, valid_schema: valid_schema}
    end

    test "valid schema passes", %{valid_schema: schema} do
      assert {:ok, ^schema} = Schema.validate(schema)
    end

    test "rejects empty name" do
      schema = Schema.new("") |> Schema.add_field(Field.primary_key("id", :int64))
      {:error, error} = Schema.validate(schema)
      assert error.field == :name
      assert error.message =~ "cannot be empty"
    end

    test "rejects name exceeding 255 characters" do
      schema =
        Schema.new(String.duplicate("a", 256))
        |> Schema.add_field(Field.primary_key("id", :int64))

      {:error, error} = Schema.validate(schema)
      assert error.field == :name
    end

    test "rejects invalid name characters" do
      schema =
        Schema.new("my-collection")
        |> Schema.add_field(Field.primary_key("id", :int64))

      {:error, error} = Schema.validate(schema)
      assert error.field == :name
      assert error.message =~ "must start with a letter"
    end

    test "rejects schema without fields" do
      schema = Schema.new("movies")
      {:error, error} = Schema.validate(schema)
      assert error.field == :fields
      assert error.message =~ "at least one field"
    end

    test "rejects schema without primary key" do
      schema =
        Schema.new("movies")
        |> Schema.add_field(Field.vector("embedding", 128))

      {:error, error} = Schema.validate(schema)
      assert error.field == :primary_key
      assert error.message =~ "exactly one primary key"
    end

    test "rejects schema with multiple primary keys" do
      schema =
        Schema.new("movies")
        |> Schema.add_field(Field.primary_key("id1", :int64))
        |> Schema.add_field(Field.primary_key("id2", :int64))

      {:error, error} = Schema.validate(schema)
      assert error.field == :primary_key
      assert error.message =~ "found 2 primary keys"
    end

    test "rejects duplicate field names" do
      schema =
        Schema.new("movies")
        |> Schema.add_field(Field.primary_key("id", :int64))
        |> Schema.add_field(Field.varchar("title", 256))
        |> Schema.add_field(Field.varchar("title", 512))

      {:error, error} = Schema.validate(schema)
      assert error.field == :fields
      assert error.message =~ "duplicate field names"
      assert error.message =~ "title"
    end

    test "validates individual fields" do
      schema =
        Schema.new("movies")
        |> Schema.add_field(Field.primary_key("id", :int64))
        |> Schema.add_field(Field.new("embedding", :float_vector))

      {:error, error} = Schema.validate(schema)
      assert error.field == :dimension
    end
  end

  describe "validate!/1" do
    test "returns schema when valid" do
      schema =
        Schema.new("movies")
        |> Schema.add_field(Field.primary_key("id", :int64))
        |> Schema.add_field(Field.vector("embedding", 128))

      assert Schema.validate!(schema) == schema
    end

    test "raises on invalid schema" do
      schema = Schema.new("movies")

      assert_raise Milvex.Errors.Invalid, fn ->
        Schema.validate!(schema)
      end
    end
  end

  describe "to_proto/1" do
    test "converts schema to proto" do
      schema =
        Schema.new("movies")
        |> Schema.description("Movie collection")
        |> Schema.add_field(Field.primary_key("id", :int64))
        |> Schema.add_field(Field.vector("embedding", 128))
        |> Schema.enable_dynamic_field()

      proto = Schema.to_proto(schema)

      assert %CollectionSchema{} = proto
      assert proto.name == "movies"
      assert proto.description == "Movie collection"
      assert proto.enable_dynamic_field == true
      assert length(proto.fields) == 2
    end

    test "handles nil description" do
      schema =
        Schema.new("movies")
        |> Schema.add_field(Field.primary_key("id", :int64))

      proto = Schema.to_proto(schema)
      assert proto.description == ""
    end

    test "separates struct_array_fields from regular fields" do
      struct_fields = [
        Field.varchar("text", 4096),
        Field.vector("embedding", 1024)
      ]

      schema =
        Schema.new("conversations")
        |> Schema.add_field(Field.primary_key("id", :varchar, max_length: 64))
        |> Schema.add_field(Field.varchar("recording_id", 36))
        |> Schema.add_field(
          Field.array("sentences", :struct, max_capacity: 50, struct_schema: struct_fields)
        )

      proto = Schema.to_proto(schema)

      assert length(proto.fields) == 2
      assert length(proto.struct_array_fields) == 1

      [struct_array_field] = proto.struct_array_fields
      assert struct_array_field.name == "sentences"
      assert length(struct_array_field.fields) == 2
    end
  end

  describe "from_proto/1" do
    test "converts proto to schema" do
      proto = %CollectionSchema{
        name: "movies",
        description: "Movie collection",
        enable_dynamic_field: true,
        fields: [
          %Milvex.Milvus.Proto.Schema.FieldSchema{
            name: "id",
            data_type: :Int64,
            is_primary_key: true
          }
        ]
      }

      schema = Schema.from_proto(proto)

      assert schema.name == "movies"
      assert schema.description == "Movie collection"
      assert schema.enable_dynamic_field == true
      assert length(schema.fields) == 1
    end

    test "handles empty description" do
      proto = %CollectionSchema{
        name: "movies",
        description: "",
        fields: []
      }

      schema = Schema.from_proto(proto)
      assert schema.description == nil
    end

    test "roundtrip conversion preserves data" do
      original =
        Schema.new("movies")
        |> Schema.description("Movie embeddings collection")
        |> Schema.add_field(Field.primary_key("id", :int64, auto_id: true))
        |> Schema.add_field(Field.varchar("title", 512))
        |> Schema.add_field(Field.vector("embedding", 768))
        |> Schema.enable_dynamic_field()

      proto = Schema.to_proto(original)
      restored = Schema.from_proto(proto)

      assert restored.name == original.name
      assert restored.description == original.description
      assert restored.enable_dynamic_field == original.enable_dynamic_field
      assert length(restored.fields) == length(original.fields)

      for {orig, rest} <- Enum.zip(original.fields, restored.fields) do
        assert rest.name == orig.name
        assert rest.data_type == orig.data_type
      end
    end
  end

  describe "helper functions" do
    setup do
      schema =
        Schema.new("movies")
        |> Schema.add_field(Field.primary_key("id", :int64))
        |> Schema.add_field(Field.varchar("title", 256))
        |> Schema.add_field(Field.scalar("year", :int32))
        |> Schema.add_field(Field.vector("embedding", 128))
        |> Schema.add_field(Field.vector("image_embedding", 512, type: :float16_vector))

      {:ok, schema: schema}
    end

    test "primary_key_field/1 returns the primary key", %{schema: schema} do
      pk = Schema.primary_key_field(schema)
      assert pk.name == "id"
      assert pk.is_primary_key == true
    end

    test "primary_key_field/1 returns nil when no primary key" do
      schema = Schema.new("test") |> Schema.add_field(Field.varchar("name", 100))
      assert Schema.primary_key_field(schema) == nil
    end

    test "vector_fields/1 returns all vector fields", %{schema: schema} do
      vectors = Schema.vector_fields(schema)
      assert length(vectors) == 2
      assert Enum.all?(vectors, &Field.vector_type?(&1.data_type))
    end

    test "scalar_fields/1 returns all scalar fields", %{schema: schema} do
      scalars = Schema.scalar_fields(schema)
      names = Enum.map(scalars, & &1.name)
      assert "id" in names
      assert "title" in names
      assert "year" in names
      refute "embedding" in names
    end

    test "get_field/2 finds field by name", %{schema: schema} do
      field = Schema.get_field(schema, "title")
      assert field.name == "title"
      assert field.data_type == :varchar
    end

    test "get_field/2 accepts atom name", %{schema: schema} do
      field = Schema.get_field(schema, :embedding)
      assert field.name == "embedding"
    end

    test "get_field/2 returns nil for unknown field", %{schema: schema} do
      assert Schema.get_field(schema, "unknown") == nil
    end

    test "field_names/1 returns all field names", %{schema: schema} do
      names = Schema.field_names(schema)
      assert names == ["id", "title", "year", "embedding", "image_embedding"]
    end

    test "struct_array_fields/1 returns array_of_struct fields" do
      struct_fields = [Field.varchar("text", 4096)]

      schema =
        Schema.new("test")
        |> Schema.add_field(Field.primary_key("id", :int64))
        |> Schema.add_field(
          Field.array("sentences", :struct, max_capacity: 50, struct_schema: struct_fields)
        )
        |> Schema.add_field(Field.array("tags", :varchar, max_capacity: 10, max_length: 64))

      struct_arrays = Schema.struct_array_fields(schema)
      assert length(struct_arrays) == 1
      assert hd(struct_arrays).name == "sentences"
    end
  end

  describe "full workflow" do
    test "complete schema creation workflow" do
      schema =
        Schema.new("products")
        |> Schema.description("Product catalog with semantic search")
        |> Schema.add_field(Field.primary_key("sku", :varchar, max_length: 32))
        |> Schema.add_field(Field.varchar("name", 512))
        |> Schema.add_field(Field.varchar("description", 2048, nullable: true))
        |> Schema.add_field(Field.scalar("price", :float))
        |> Schema.add_field(Field.scalar("stock", :int32, default: 0))
        |> Schema.add_field(Field.array("tags", :varchar, max_capacity: 20, max_length: 64))
        |> Schema.add_field(Field.vector("name_embedding", 384))
        |> Schema.add_field(Field.vector("image_embedding", 512, type: :float16_vector))
        |> Schema.enable_dynamic_field()

      assert {:ok, validated} = Schema.validate(schema)
      assert validated.name == "products"
      assert length(validated.fields) == 8

      proto = Schema.to_proto(validated)
      assert proto.name == "products"
      assert proto.enable_dynamic_field == true
    end
  end
end
