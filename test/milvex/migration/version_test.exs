defmodule Milvex.Migration.VersionTest do
  use ExUnit.Case, async: true

  alias Milvex.Migration.Version, as: MigrationVersion

  doctest Milvex.Migration.Version

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

    test "pads a two-component version to three" do
      assert MigrationVersion.coerce("2.6") == "2.6.0"
    end

    test "pads a single-component version" do
      assert MigrationVersion.coerce("2") == "2.0.0"
    end

    test "strips build metadata" do
      assert MigrationVersion.coerce("2.6.1+build.5") == "2.6.1"
    end

    test "truncates extra components" do
      assert MigrationVersion.coerce("2.6.0.4") == "2.6.0"
    end

    test "falls back to 0.0.0 for an unparseable version" do
      assert MigrationVersion.coerce("") == "0.0.0"
      assert MigrationVersion.coerce("unknown") == "0.0.0"
    end

    test "output is always parseable by Version.parse/1" do
      for v <- ["", "2.6", "v2.6.1+build", "2.6.1-dev", "garbage", "2", "2.6.0.4", "v2.6.1"] do
        assert {:ok, _} = Version.parse(MigrationVersion.coerce(v)),
               "coerce(#{inspect(v)}) should be valid semver"
      end
    end
  end

  describe "drop_field_supported_at/0" do
    test "returns the documented cutoff" do
      assert MigrationVersion.drop_field_supported_at() == "2.6.0"
    end
  end
end
