# frozen_string_literal: true

require "test_helper"
require "open3"

class CliTest < ActiveSupport::TestCase
  EXE = File.expand_path("../bin/kamal-lint", __dir__)
  GEMFILE = File.expand_path("../Gemfile", __dir__)

  def run_cli(*args, dir: nil)
    env = { "BUNDLE_GEMFILE" => GEMFILE }
    opts = dir ? { chdir: dir } : {}
    Open3.capture3(env, "bundle", "exec", EXE, *args, **opts)
  end

  def with_dir
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "config"))
      yield dir
    end
  end

  def test_version
    out, _err, status = run_cli("version")
    assert_equal 0, status.exitstatus
    assert_includes out, "kamal-lint #{Kamal::Lint::VERSION}"
  end

  def test_list_checks
    out, _err, status = run_cli("list-checks")
    assert_equal 0, status.exitstatus
    assert_includes out, "secret-not-declared"
    assert_includes out, "traefik-legacy-keys"
    assert_match(/Total: \d+ checks/, out)
  end

  def test_exit_one_on_errors
    with_dir do |dir|
      File.write(File.join(dir, "config", "deploy.yml"), "image: i\n")
      _out, _err, status = run_cli("--no-color", "--fail-on", "error", dir: dir)
      assert_equal 1, status.exitstatus
    end
  end

  def test_exit_zero_on_clean_when_threshold_error
    with_dir do |dir|
      File.write(File.join(dir, "config", "deploy.yml"), <<~YAML)
        service: app
        image: ghcr.io/x/x
        servers:
          - 1.2.3.4
        builder:
          arch: amd64
        registry:
          server: ghcr.io
          username: u
          password: p
        proxy:
          host: x.example.com
          healthcheck:
            path: /up
      YAML
      FileUtils.mkdir_p(File.join(dir, ".kamal"))
      File.write(File.join(dir, ".kamal", "secrets"), "")
      File.write(File.join(dir, ".gitignore"), ".kamal/secrets\n")
      _out, _err, status = run_cli("--no-color", "--fail-on", "error", dir: dir)
      assert_equal 0, status.exitstatus
    end
  end

  def test_json_format
    with_dir do |dir|
      File.write(File.join(dir, "config", "deploy.yml"), "image: i\n")
      out, _err, _status = run_cli("--format", "json", "--no-color", dir: dir)
      payload = JSON.parse(out)
      assert_equal Kamal::Lint::VERSION, payload["kamal_lint_version"]
      assert_kind_of Array, payload["findings"]
    end
  end

  def test_github_format
    with_dir do |dir|
      File.write(File.join(dir, "config", "deploy.yml"), "image: i\n")
      out, _err, _status = run_cli("--format", "github", "--no-color", dir: dir)
      assert_match(/^::error /, out)
    end
  end

  def test_exit_two_on_missing_config
    Dir.mktmpdir do |dir|
      _out, _err, status = run_cli("--no-color", dir: dir)
      assert_equal 2, status.exitstatus
    end
  end
end
