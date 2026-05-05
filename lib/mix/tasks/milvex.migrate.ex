defmodule Mix.Tasks.Milvex.Migrate do
  @shortdoc "Reconciles Milvex.Collection DSL modules with the live Milvus state"
  @moduledoc """
  Diffs Milvex.Collection DSL modules against the live Milvus state and applies
  the result.

  ## Usage

      mix milvex.migrate --plan
      mix milvex.migrate --apply
      mix milvex.migrate --apply --allow-drop
      mix milvex.migrate --plan --format json
      mix milvex.migrate --apply --module MyApp.Movies --prefix tenant_a_

  See `Milvex.Migration.CLI` for the full flag list and exit-code semantics.
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {:ok, _} = Application.ensure_all_started(:milvex)
    {code, output} = Milvex.Migration.CLI.run(argv)
    IO.binwrite(output)
    if code != 0, do: System.halt(code)
    :ok
  end
end
