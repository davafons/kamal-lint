# frozen_string_literal: true

require "test_helper"

class LoaderTest < ActiveSupport::TestCase
  def test_raises_when_config_missing
    assert_raises(Kamal::Lint::ConfigNotFoundError) do
      Kamal::Lint::Loader.load(config_file: "/nonexistent.yml")
    end
  end

  def test_parses_and_builds_line_index
    yaml = <<~YAML
      service: myapp
      image: myorg/myapp
      env:
        secret:
          - K
    YAML
    with_project(yaml: yaml, secrets: "K=v\n") do
      ctx = Kamal::Lint::Loader.load(config_file: "config/deploy.yml", kamal_version: "2.11.0")
      assert_equal "myapp", ctx.parsed["service"]
      assert_equal 1, ctx.line_for([ "service" ])
      assert_equal 4, ctx.line_for([ "env", "secret" ])
      assert_equal 5, ctx.line_for([ "env", "secret", "0" ])
      assert_equal [ "K" ], ctx.secrets
    end
  end

  def test_destination_overrides_merge
    with_project(
      yaml: "service: myapp\nimage: a\n",
      destination_yaml: "image: b\n",
      destination_name: "production"
    ) do
      ctx = Kamal::Lint::Loader.load(
        config_file: "config/deploy.yml",
        destination: "production",
        kamal_version: "2.11.0"
      )
      assert_equal "myapp", ctx.parsed["service"]
      assert_equal "b", ctx.parsed["image"]
      assert_equal({ "image" => "b" }, ctx.override_parsed)
    end
  end

  def test_captures_kamal_load_errors_without_raising
    with_project(yaml: "this is not a valid kamal config\n") do
      ctx = Kamal::Lint::Loader.load(config_file: "config/deploy.yml", kamal_version: "2.11.0")
      refute ctx.kamal_loaded
      assert_kind_of StandardError, ctx.kamal_load_error
    end
  end

  def test_deep_merge_hashes
    base = { "a" => { "b" => 1, "c" => 2 } }
    over = { "a" => { "c" => 99, "d" => 3 } }
    assert_equal({ "a" => { "b" => 1, "c" => 99, "d" => 3 } }, Kamal::Lint::Loader.deep_merge(base, over))
  end

  def test_deep_merge_replaces_scalars_and_arrays
    assert_equal({ "a" => [ 2 ] }, Kamal::Lint::Loader.deep_merge({ "a" => [ 1 ] }, { "a" => [ 2 ] }))
    assert_equal({ "a" => 2 }, Kamal::Lint::Loader.deep_merge({ "a" => 1 }, { "a" => 2 }))
  end
end
