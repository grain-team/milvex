defmodule Mix.Tasks.Milvex.MigrateTest do
  use ExUnit.Case, async: false
  use Mimic

  import ExUnit.CaptureIO

  setup :verify_on_exit!

  test "delegates to CLI.run/1 and prints output" do
    Milvex.Migration.CLI
    |> expect(:run, fn ["--plan"] -> {0, "ok\n"} end)

    captured = capture_io(fn -> Mix.Tasks.Milvex.Migrate.run(["--plan"]) end)
    assert captured == "ok\n"
  end
end
