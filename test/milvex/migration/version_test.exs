defmodule Milvex.Migration.VersionTest do
  use ExUnit.Case, async: true

  alias Milvex.Migration.Version, as: MigrationVersion

  describe "coerce/1" do
    test "strips a leading v" do
      assert MigrationVersion.coerce("v2.6.1") == "2.6.1"
    end

    test "passes plain semver through" do
      assert MigrationVersion.coerce("2.6.1") == "2.6.1"
    end

    test "drops a pre-release suffix" do
      assert MigrationVersion.coerce("2.6.1-dev") == "2.6.1"
      assert MigrationVersion.coerce("v2.6.1-rc.1") == "2.6.1"
    end

    test "trims whitespace" do
      assert MigrationVersion.coerce("  v2.6.1  ") == "2.6.1"
      assert MigrationVersion.coerce("\t2.6.1\n") == "2.6.1"
    end
  end

  describe "drop_field_supported_at/0" do
    test "returns the documented cutoff" do
      assert MigrationVersion.drop_field_supported_at() == "2.6.0"
    end
  end
end
