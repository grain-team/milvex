defmodule Milvex.AlterTest do
  use ExUnit.Case, async: true
  use Mimic

  @moduletag :capture_log

  alias Milvex.Connection
  alias Milvex.Function
  alias Milvex.RPC
  alias Milvex.Schema.Field

  alias Milvex.Milvus.Proto.Common.KeyValuePair
  alias Milvex.Milvus.Proto.Common.Status

  alias Milvex.Milvus.Proto.Milvus.AddCollectionFieldRequest
  alias Milvex.Milvus.Proto.Milvus.AddCollectionFunctionRequest
  alias Milvex.Milvus.Proto.Milvus.AlterCollectionFieldRequest
  alias Milvex.Milvus.Proto.Milvus.AlterCollectionFunctionRequest
  alias Milvex.Milvus.Proto.Milvus.AlterCollectionRequest
  alias Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaRequest
  alias Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaResponse
  alias Milvex.Milvus.Proto.Milvus.AlterIndexRequest
  alias Milvex.Milvus.Proto.Milvus.DropCollectionFunctionRequest
  alias Milvex.Milvus.Proto.Milvus.GetLoadStateRequest
  alias Milvex.Milvus.Proto.Milvus.GetLoadStateResponse
  alias Milvex.Milvus.Proto.Milvus.GetVersionRequest
  alias Milvex.Milvus.Proto.Milvus.GetVersionResponse
  alias Milvex.Milvus.Proto.Schema.FunctionSchema

  @channel %GRPC.Channel{host: "localhost", port: 19_530}
  @config Milvex.Config.defaults()

  defmodule MoviesCollection do
    use Milvex.Collection

    collection do
      name "movies"

      fields do
        primary_key :id, :int64, auto_id: true
        varchar :title, 256
        vector :embedding, 128
      end
    end
  end

  setup :verify_on_exit!

  defp stub_channel do
    stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel, @config} end)
  end

  describe "get_version/2" do
    test "returns version string on success" do
      stub_channel()

      expect(RPC, :call, fn _channel, _stub, :get_version, request, _opts ->
        assert %GetVersionRequest{} = request
        {:ok, %GetVersionResponse{status: %Status{code: 0}, version: "2.6.1"}}
      end)

      assert {:ok, "2.6.1"} = Milvex.get_version(:fake_conn)
    end

    test "returns error on non-zero status" do
      stub_channel()

      expect(RPC, :call, fn _, _, :get_version, _request, _opts ->
        {:ok,
         %GetVersionResponse{
           status: %Status{code: 1, reason: "boom"},
           version: ""
         }}
      end)

      assert {:error, %Milvex.Errors.Grpc{}} = Milvex.get_version(:fake_conn)
    end

    test "propagates timeout option to RPC.call" do
      stub_channel()

      expect(RPC, :call, fn _, _, :get_version, _request, opts ->
        assert opts[:timeout] == 7_000
        {:ok, %GetVersionResponse{status: %Status{code: 0}, version: "2.6.0"}}
      end)

      assert {:ok, "2.6.0"} = Milvex.get_version(:fake_conn, timeout: 7_000)
    end
  end

  describe "get_load_state/3" do
    test "maps :LoadStateLoaded to :loaded" do
      stub_channel()

      expect(RPC, :call, fn _, _, :get_load_state, request, _opts ->
        assert %GetLoadStateRequest{
                 collection_name: "movies",
                 db_name: "main"
               } = request

        {:ok, %GetLoadStateResponse{status: %Status{code: 0}, state: :LoadStateLoaded}}
      end)

      assert {:ok, :loaded} =
               Milvex.get_load_state(:fake_conn, "movies", db_name: "main")
    end

    test "maps :LoadStateNotLoad to :not_loaded" do
      stub_channel()

      expect(RPC, :call, fn _, _, :get_load_state, _request, _opts ->
        {:ok, %GetLoadStateResponse{status: %Status{code: 0}, state: :LoadStateNotLoad}}
      end)

      assert {:ok, :not_loaded} = Milvex.get_load_state(:fake_conn, "movies")
    end

    test "maps :LoadStateLoading to :loading" do
      stub_channel()

      expect(RPC, :call, fn _, _, :get_load_state, _request, _opts ->
        {:ok, %GetLoadStateResponse{status: %Status{code: 0}, state: :LoadStateLoading}}
      end)

      assert {:ok, :loading} = Milvex.get_load_state(:fake_conn, "movies")
    end

    test "maps :LoadStateNotExist to :not_exist" do
      stub_channel()

      expect(RPC, :call, fn _, _, :get_load_state, _request, _opts ->
        {:ok, %GetLoadStateResponse{status: %Status{code: 0}, state: :LoadStateNotExist}}
      end)

      assert {:ok, :not_exist} = Milvex.get_load_state(:fake_conn, "movies")
    end

    test "passes :partition_names through" do
      stub_channel()

      expect(RPC, :call, fn _, _, :get_load_state, request, _opts ->
        assert request.partition_names == ["p1", "p2"]
        {:ok, %GetLoadStateResponse{status: %Status{code: 0}, state: :LoadStateLoaded}}
      end)

      assert {:ok, :loaded} =
               Milvex.get_load_state(:fake_conn, "movies", partition_names: ["p1", "p2"])
    end
  end

  describe "alter_collection/3" do
    test "sends properties and delete_keys" do
      stub_channel()

      expect(RPC, :call, fn _, _, :alter_collection, request, _opts ->
        assert %AlterCollectionRequest{
                 collection_name: "movies",
                 db_name: "",
                 properties: properties,
                 delete_keys: delete_keys
               } = request

        assert [%KeyValuePair{key: "ttl.seconds", value: "3600"}] = properties
        assert ["mmap.enabled"] = delete_keys
        {:ok, %Status{code: 0}}
      end)

      assert :ok =
               Milvex.alter_collection(:fake_conn, "movies",
                 set: ["ttl.seconds": 3600],
                 delete: [:"mmap.enabled"]
               )
    end

    test "defaults to empty properties and delete_keys" do
      stub_channel()

      expect(RPC, :call, fn _, _, :alter_collection, request, _opts ->
        assert request.properties == []
        assert request.delete_keys == []
        {:ok, %Status{code: 0}}
      end)

      assert :ok = Milvex.alter_collection(:fake_conn, "movies")
    end

    test "returns {:error, _} on non-zero status" do
      stub_channel()

      expect(RPC, :call, fn _, _, :alter_collection, _request, _opts ->
        {:ok, %Status{code: 5, reason: "nope"}}
      end)

      assert {:error, %Milvex.Errors.Grpc{}} =
               Milvex.alter_collection(:fake_conn, "movies", set: [foo: "bar"])
    end
  end

  describe "alter_collection_field/4" do
    test "sends field-scoped properties" do
      stub_channel()

      expect(RPC, :call, fn _, _, :alter_collection_field, request, _opts ->
        assert %AlterCollectionFieldRequest{
                 collection_name: "movies",
                 field_name: "title",
                 properties: [%KeyValuePair{key: "max_length", value: "1024"}],
                 delete_keys: []
               } = request

        {:ok, %Status{code: 0}}
      end)

      assert :ok =
               Milvex.alter_collection_field(:fake_conn, "movies", "title",
                 set: [max_length: 1024]
               )
    end

    test "supports delete keys" do
      stub_channel()

      expect(RPC, :call, fn _, _, :alter_collection_field, request, _opts ->
        assert request.delete_keys == ["mmap.enabled"]
        {:ok, %Status{code: 0}}
      end)

      assert :ok =
               Milvex.alter_collection_field(:fake_conn, "movies", "title",
                 delete: [:"mmap.enabled"]
               )
    end
  end

  describe "add_collection_field/4" do
    test "encodes field schema and sends bytes" do
      stub_channel()
      field = Field.varchar("description", 1024, nullable: true)

      expect(RPC, :call, fn _, _, :add_collection_field, request, _opts ->
        assert %AddCollectionFieldRequest{
                 collection_name: "movies",
                 schema: schema_bytes
               } = request

        assert is_binary(schema_bytes)
        assert byte_size(schema_bytes) > 0
        {:ok, %Status{code: 0}}
      end)

      assert :ok = Milvex.add_collection_field(:fake_conn, "movies", field)
    end

    test "passes db_name through" do
      stub_channel()
      field = Field.varchar("description", 1024, nullable: true)

      expect(RPC, :call, fn _, _, :add_collection_field, request, _opts ->
        assert request.db_name == "tenant_a"
        {:ok, %Status{code: 0}}
      end)

      assert :ok =
               Milvex.add_collection_field(:fake_conn, "movies", field, db_name: "tenant_a")
    end
  end

  describe "alter_collection_schema/3" do
    test "builds add_request with field_infos for :add_fields" do
      stub_channel()
      field = Field.varchar("description", 1024, nullable: true)

      expect(RPC, :call, fn _, _, :alter_collection_schema, request, _opts ->
        assert %AlterCollectionSchemaRequest{
                 collection_name: "movies",
                 action: %{op: {:add_request, add_request}}
               } = request

        assert [%{field_schema: %{name: "description"}}] = add_request.field_infos
        assert add_request.do_physical_backfill == false

        {:ok,
         %AlterCollectionSchemaResponse{
           alter_status: %Status{code: 0},
           index_status: %Status{code: 0}
         }}
      end)

      assert :ok =
               Milvex.alter_collection_schema(:fake_conn, "movies", add_fields: [field])
    end

    test "builds drop_request with field_name for :drop_fields" do
      stub_channel()

      expect(RPC, :call, fn _, _, :alter_collection_schema, request, _opts ->
        assert %{op: {:drop_request, drop_request}} = request.action

        assert %{field_identifier: {:field_name, "legacy"}} = drop_request

        {:ok,
         %AlterCollectionSchemaResponse{
           alter_status: %Status{code: 0},
           index_status: %Status{code: 0}
         }}
      end)

      assert :ok =
               Milvex.alter_collection_schema(:fake_conn, "movies", drop_fields: ["legacy"])
    end

    test "passes do_physical_backfill flag through" do
      stub_channel()
      field = Field.varchar("description", 1024, nullable: true)

      expect(RPC, :call, fn _, _, :alter_collection_schema, request, _opts ->
        assert {:add_request, add_request} = request.action.op
        assert add_request.do_physical_backfill == true

        {:ok,
         %AlterCollectionSchemaResponse{
           alter_status: %Status{code: 0},
           index_status: %Status{code: 0}
         }}
      end)

      assert :ok =
               Milvex.alter_collection_schema(:fake_conn, "movies",
                 add_fields: [field],
                 do_physical_backfill: true
               )
    end

    test "returns error when alter_status is non-zero" do
      stub_channel()

      expect(RPC, :call, fn _, _, :alter_collection_schema, _req, _opts ->
        {:ok,
         %AlterCollectionSchemaResponse{
           alter_status: %Status{code: 5, reason: "alter failed"},
           index_status: %Status{code: 0}
         }}
      end)

      assert {:error, %Milvex.Errors.Grpc{}} =
               Milvex.alter_collection_schema(:fake_conn, "movies", drop_fields: ["legacy"])
    end

    test "returns error when index_status is non-zero" do
      stub_channel()

      expect(RPC, :call, fn _, _, :alter_collection_schema, _req, _opts ->
        {:ok,
         %AlterCollectionSchemaResponse{
           alter_status: %Status{code: 0},
           index_status: %Status{code: 7, reason: "index failed"}
         }}
      end)

      assert {:error, %Milvex.Errors.Grpc{}} =
               Milvex.alter_collection_schema(:fake_conn, "movies", drop_fields: ["legacy"])
    end

    test "returns Invalid error when drop_fields has more than one entry" do
      stub_channel()

      assert {:error, %Milvex.Errors.Invalid{} = error} =
               Milvex.alter_collection_schema(:fake_conn, "movies", drop_fields: ["a", "b"])

      assert error.message =~
               "AlterCollectionSchema drops at most one field per call; issue multiple calls"
    end

    test "returns Invalid error when drop_functions is supplied" do
      stub_channel()

      assert {:error, %Milvex.Errors.Invalid{} = error} =
               Milvex.alter_collection_schema(:fake_conn, "movies", drop_functions: ["bm25"])

      assert error.message =~ "Milvex.drop_collection_function/4"
    end

    test "returns Invalid error when no add/drop opts are supplied" do
      stub_channel()

      assert {:error, %Milvex.Errors.Invalid{} = error} =
               Milvex.alter_collection_schema(:fake_conn, "movies")

      assert error.message =~
               "alter_collection_schema requires :add_fields, :add_functions, or :drop_fields"
    end

    test "resolves collection name from a Milvex.Collection module" do
      stub_channel()

      expect(RPC, :call, fn _, _, :alter_collection_schema, request, _opts ->
        assert request.collection_name == "movies"

        {:ok,
         %AlterCollectionSchemaResponse{
           alter_status: %Status{code: 0},
           index_status: %Status{code: 0}
         }}
      end)

      assert :ok =
               Milvex.alter_collection_schema(:fake_conn, MoviesCollection,
                 drop_fields: ["legacy"]
               )
    end
  end

  describe "alter_index/4" do
    test "sends index_name with extra_params and delete_keys" do
      stub_channel()

      expect(RPC, :call, fn _, _, :alter_index, request, _opts ->
        assert %AlterIndexRequest{
                 collection_name: "movies",
                 index_name: "embedding_idx",
                 extra_params: [%KeyValuePair{key: "mmap.enabled", value: "true"}],
                 delete_keys: ["other"]
               } = request

        {:ok, %Status{code: 0}}
      end)

      assert :ok =
               Milvex.alter_index(:fake_conn, "movies", "embedding_idx",
                 set: ["mmap.enabled": true],
                 delete: [:other]
               )
    end
  end

  describe "add_collection_function/4" do
    test "sends function schema in request" do
      stub_channel()

      function = %Function{
        name: "bm25",
        type: :BM25,
        input_field_names: ["content"],
        output_field_names: ["sparse"],
        params: %{}
      }

      expect(RPC, :call, fn _, _, :add_collection_function, request, _opts ->
        assert %AddCollectionFunctionRequest{
                 collection_name: "movies",
                 functionSchema: %FunctionSchema{name: "bm25", type: :BM25}
               } = request

        {:ok, %Status{code: 0}}
      end)

      assert :ok = Milvex.add_collection_function(:fake_conn, "movies", function)
    end
  end

  describe "alter_collection_function/4" do
    test "sends function schema with function_name" do
      stub_channel()

      function = %Function{
        name: "bm25",
        type: :BM25,
        input_field_names: ["content"],
        output_field_names: ["sparse"],
        params: %{}
      }

      expect(RPC, :call, fn _, _, :alter_collection_function, request, _opts ->
        assert %AlterCollectionFunctionRequest{
                 collection_name: "movies",
                 function_name: "bm25",
                 functionSchema: %FunctionSchema{name: "bm25"}
               } = request

        {:ok, %Status{code: 0}}
      end)

      assert :ok = Milvex.alter_collection_function(:fake_conn, "movies", function)
    end
  end

  describe "drop_collection_function/4" do
    test "drops by function name" do
      stub_channel()

      expect(RPC, :call, fn _, _, :drop_collection_function, request, _opts ->
        assert %DropCollectionFunctionRequest{
                 collection_name: "movies",
                 function_name: "bm25"
               } = request

        {:ok, %Status{code: 0}}
      end)

      assert :ok = Milvex.drop_collection_function(:fake_conn, "movies", "bm25")
    end
  end

  describe "channel resolution failures" do
    test "alter_collection returns connection error" do
      stub(Connection, :get_channel, fn _conn, _opts -> {:error, :not_connected} end)

      assert {:error, :not_connected} = Milvex.alter_collection(:fake_conn, "movies")
    end

    test "get_version returns connection error" do
      stub(Connection, :get_channel, fn _conn, _opts -> {:error, :not_connected} end)

      assert {:error, :not_connected} = Milvex.get_version(:fake_conn)
    end
  end
end
