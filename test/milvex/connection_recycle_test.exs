defmodule Milvex.ConnectionRecycleTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Milvex.Connection
  alias Milvex.Milvus.Proto.Common.Status
  alias Milvex.Milvus.Proto.Milvus.GetVersionResponse

  @moduletag :capture_log

  setup :set_mimic_global

  describe "channel recycling" do
    test "pool serves channels across recycle without a not_connected window" do
      stub_successful_connect()

      {:ok, pool} =
        Connection.start_link(
          host: "localhost",
          pool_size: 2,
          channel_max_age: 1_000,
          channel_max_age_jitter: 0.0
        )

      eventually(fn -> assert {:ok, %GRPC.Channel{}, _config} = Connection.get_channel(pool) end)

      # Strictly poll across several recycle cycles: get_channel must never
      # return a not_connected error, and the underlying channels must turn over.
      pids =
        Enum.map(1..60, fn _ ->
          {:ok, channel, _config} = Connection.get_channel(pool)
          Process.sleep(50)
          channel.adapter_payload.conn_pid
        end)
        |> Enum.uniq()

      assert length(pids) > 3
    end

    test "old channel stays open for the drain grace, then closes" do
      stub_successful_connect()

      {:ok, conn} =
        Connection.start_link(
          host: "localhost",
          channel_max_age: 3_000,
          channel_max_age_jitter: 0.0,
          timeout: 1_000
        )

      eventually(fn -> assert {:ok, %GRPC.Channel{}, _} = Connection.get_channel(conn) end)
      {:ok, initial, _} = Connection.get_channel(conn)
      initial_pid = initial.adapter_payload.conn_pid

      new_pid =
        eventually(
          fn ->
            {:ok, channel, _} = Connection.get_channel(conn)
            pid = channel.adapter_payload.conn_pid
            assert pid != initial_pid
            pid
          end,
          250
        )

      # Make-before-break: the old channel is still alive during the drain grace.
      assert Process.alive?(initial_pid)
      assert Process.alive?(new_pid)

      # After the drain grace (2x timeout = 2s) the old channel is closed.
      eventually(fn -> refute Process.alive?(initial_pid) end, 250)
    end

    test "recycle failure keeps the existing channel published" do
      {:ok, counter} = Agent.start_link(fn -> 0 end)

      GRPC.Stub
      |> stub(:connect, fn _address, _opts ->
        n = Agent.get_and_update(counter, fn n -> {n, n + 1} end)

        if n == 0 do
          conn_pid = spawn(fn -> Process.sleep(:infinity) end)
          {:ok, %GRPC.Channel{adapter_payload: %{conn_pid: conn_pid}}}
        else
          {:error, :econnrefused}
        end
      end)
      |> stub(:disconnect, fn channel ->
        Process.exit(channel.adapter_payload.conn_pid, :kill)
        {:ok, channel}
      end)

      {:ok, conn} =
        Connection.start_link(
          host: "localhost",
          channel_max_age: 1_000,
          channel_max_age_jitter: 0.0
        )

      eventually(fn -> assert {:ok, %GRPC.Channel{}, _} = Connection.get_channel(conn) end)
      {:ok, initial, _} = Connection.get_channel(conn)
      initial_pid = initial.adapter_payload.conn_pid

      # The recycle attempt at 1s fails; the retry is 30s away, so the original
      # channel must remain the published one.
      Process.sleep(1_500)

      assert {:ok, %GRPC.Channel{adapter_payload: %{conn_pid: ^initial_pid}}, _} =
               Connection.get_channel(conn)
    end

    test "draining channel death does not disturb the newly published channel" do
      stub_successful_connect()

      {:ok, conn} =
        Connection.start_link(
          host: "localhost",
          channel_max_age: 1_000,
          channel_max_age_jitter: 0.0
        )

      eventually(fn -> assert {:ok, %GRPC.Channel{}, _} = Connection.get_channel(conn) end)
      {:ok, initial, _} = Connection.get_channel(conn)
      initial_pid = initial.adapter_payload.conn_pid

      new_pid =
        eventually(
          fn ->
            {:ok, channel, _} = Connection.get_channel(conn)
            pid = channel.adapter_payload.conn_pid
            assert pid != initial_pid
            pid
          end,
          200
        )

      draining_pid =
        eventually(fn ->
          {_state, %{draining: {draining_channel, _ref}}} = :sys.get_state(conn)
          draining_channel.adapter_payload.conn_pid
        end)

      # Simulate the old gun connection dying during the drain window.
      Process.exit(draining_pid, :kill)

      # The new channel must remain intact and served.
      eventually(fn ->
        assert {:ok, %GRPC.Channel{adapter_payload: %{conn_pid: ^new_pid}}, _} =
                 Connection.get_channel(conn)

        assert Connection.connected?(conn)
      end)

      # The draining entry is cleared.
      eventually(fn ->
        {_state, %{draining: draining}} = :sys.get_state(conn)
        assert draining == nil
      end)
    end

    test "new channel death during the drain window does not crash the FSM" do
      {:ok, gate} = Agent.start_link(fn -> :allow end)

      GRPC.Stub
      |> stub(:connect, fn _address, _opts ->
        case Agent.get(gate, & &1) do
          :allow ->
            conn_pid = spawn(fn -> Process.sleep(:infinity) end)
            {:ok, %GRPC.Channel{adapter_payload: %{conn_pid: conn_pid}}}

          :deny ->
            {:error, :econnrefused}
        end
      end)
      |> stub(:disconnect, fn channel ->
        Process.exit(channel.adapter_payload.conn_pid, :kill)
        {:ok, channel}
      end)

      {:ok, conn} =
        Connection.start_link(
          host: "localhost",
          channel_max_age: 1_000,
          channel_max_age_jitter: 0.0,
          timeout: 1_000,
          reconnect_base_delay: 100
        )

      eventually(fn -> assert {:ok, %GRPC.Channel{}, _} = Connection.get_channel(conn) end)
      {:ok, initial, _} = Connection.get_channel(conn)
      initial_pid = initial.adapter_payload.conn_pid

      # Wait for the recycle so we are inside the drain window (grace = 2s).
      new_pid =
        eventually(
          fn ->
            {:ok, channel, _} = Connection.get_channel(conn)
            pid = channel.adapter_payload.conn_pid
            assert pid != initial_pid
            pid
          end,
          200
        )

      # Kill the NEW channel while the old one is still draining, with
      # reconnects failing so the FSM stays in :reconnecting past the point
      # where the :drain_old generic timeout would have fired.
      Agent.update(gate, fn _ -> :deny end)
      Process.exit(new_pid, :kill)

      eventually(fn -> refute Connection.connected?(conn) end)

      # Ride out the (cancelled) drain timer deadline; a leaked timer would
      # crash the gen_statem with a FunctionClauseError here.
      Process.sleep(2_500)
      assert Process.alive?(conn)
      refute Connection.connected?(conn)

      # And the FSM recovers normally once connects succeed again.
      Agent.update(gate, fn _ -> :allow end)
      eventually(fn -> assert Connection.connected?(conn) end, 300)
    end
  end

  describe "detected server version lifecycle" do
    setup do
      stub_successful_connect()

      stub(GRPC.Stub, :connect, fn _address, _opts ->
        conn_pid = spawn(fn -> Process.sleep(:infinity) end)
        {:ok, %GRPC.Channel{ref: make_ref(), adapter_payload: %{conn_pid: conn_pid}}}
      end)

      {:ok, detections} = Agent.start_link(fn -> 0 end)

      stub(Milvex.RPC, :call, fn _channel_fn, _stub, :get_version, _request, _opts ->
        Agent.update(detections, &(&1 + 1))
        {:ok, %GetVersionResponse{status: %Status{code: 0}, version: "v3.0.3"}}
      end)

      %{detections: fn -> Agent.get(detections, & &1) end, version: Version.parse!("3.0.3")}
    end

    test "a detected version is returned with its channel and detected once", %{
      detections: detections,
      version: version
    } do
      {:ok, conn} = Connection.start_link(host: "localhost")
      channel = current_channel(conn)
      assert {:ok, ^channel, %{server_version: nil}} = Connection.get_channel(conn)

      assert {:ok, ^version} = Milvex.server_version(conn)
      assert {:ok, ^channel, %{server_version: ^version}} = Connection.get_channel(conn)
      assert {:ok, ^version} = Milvex.server_version(conn)
      assert detections.() == 1

      Connection.disconnect(conn)
    end

    test "a dropped channel takes its version with it", %{
      detections: detections,
      version: version
    } do
      {:ok, conn} = Connection.start_link(host: "localhost")
      channel = current_channel(conn)
      assert {:ok, ^version} = Milvex.server_version(conn)

      Process.exit(channel.adapter_payload.conn_pid, :kill)

      eventually(fn ->
        assert {:ok, replacement, %{server_version: nil}} = Connection.get_channel(conn)
        assert replacement.ref != channel.ref
      end)

      assert {:ok, ^version} = Milvex.server_version(conn)
      assert detections.() == 2

      Connection.disconnect(conn)
    end

    test "a recycled channel starts without a version", %{version: version} do
      {:ok, conn} =
        Connection.start_link(
          host: "localhost",
          channel_max_age: 1_000,
          channel_max_age_jitter: 0.0,
          timeout: 1_000
        )

      initial = current_channel(conn)
      assert {:ok, ^version} = Milvex.server_version(conn)

      eventually(fn ->
        assert {:ok, current, %{server_version: nil}} = Connection.get_channel(conn)
        assert current.ref != initial.ref
      end)

      # A caller that detected on the old channel reports late.
      Connection.put_server_version(conn, initial, version)
      assert {:ok, _current, %{server_version: nil}} = Connection.get_channel(conn)

      Connection.disconnect(conn)
    end

    test "a configured version wins over a detected one", %{version: version} do
      {:ok, conn} = Connection.start_link(host: "localhost", server_version: "2.6.6")
      channel = current_channel(conn)
      configured = Version.parse!("2.6.6")

      Connection.put_server_version(conn, channel, version)
      assert {:ok, ^channel, %{server_version: ^configured}} = Connection.get_channel(conn)

      Connection.disconnect(conn)
    end

    test "pooled channels each carry their own version", %{version: version} do
      {:ok, pool} = Connection.start_link(host: "localhost", pool_size: 2)

      [first, second] =
        eventually(fn ->
          assert [_, _] = refs = pool |> pool_versions() |> Map.keys()
          refs
        end)

      assert {:ok, ^version} = Milvex.server_version(pool)

      eventually(fn ->
        versions = pool_versions(pool)
        assert versions |> Map.keys() |> Enum.sort() == Enum.sort([first, second])
        assert versions |> Map.values() |> Enum.reject(&is_nil/1) == [version]
      end)

      Connection.disconnect(pool)
    end
  end

  describe "jittered_age/1" do
    test "returns the exact age when jitter is 0" do
      config = %{channel_max_age: 10_000, channel_max_age_jitter: 0.0}
      assert Connection.jittered_age(config) == 10_000
    end

    test "returns varying values within [age*(1-j), age]" do
      :rand.seed(:exsss, {101, 202, 303})
      config = %{channel_max_age: 10_000, channel_max_age_jitter: 0.2}
      ages = for _ <- 1..50, do: Connection.jittered_age(config)

      assert Enum.all?(ages, &(&1 >= 8_000 and &1 <= 10_000))
      assert ages |> Enum.uniq() |> length() > 1
    end

    test "returns a positive age when jitter is 1" do
      config = %{channel_max_age: 10_000, channel_max_age_jitter: 1.0}
      ages = for _ <- 1..50, do: Connection.jittered_age(config)

      assert Enum.all?(ages, &(&1 >= 1 and &1 <= 10_000))
    end
  end

  defp stub_successful_connect do
    GRPC.Stub
    |> stub(:connect, fn _address, _opts ->
      conn_pid = spawn(fn -> Process.sleep(:infinity) end)
      {:ok, %GRPC.Channel{adapter_payload: %{conn_pid: conn_pid}}}
    end)
    |> stub(:disconnect, fn channel ->
      Process.exit(channel.adapter_payload.conn_pid, :kill)
      {:ok, channel}
    end)
  end

  defp current_channel(conn) do
    eventually(fn ->
      assert {:ok, channel, _config} = Connection.get_channel(conn)
      channel
    end)
  end

  # Two picks cover both channels of a two-connection pool.
  defp pool_versions(pool) do
    Map.new(1..2, fn _ ->
      {:ok, channel, config} = Connection.get_channel(pool)
      {channel.ref, config.server_version}
    end)
  end

  defp eventually(fun, attempts \\ 100) do
    fun.()
  rescue
    error in [ExUnit.AssertionError, MatchError] ->
      if attempts > 0 do
        Process.sleep(20)
        eventually(fun, attempts - 1)
      else
        reraise error, __STACKTRACE__
      end
  end
end
