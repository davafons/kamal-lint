# frozen_string_literal: true

require "test_helper"

class RunnerTest < ActiveSupport::TestCase
  def test_valid_config_has_no_lint_findings
    result = run_runner(
      yaml: File.read(fixture_path("valid_deploy.yml")),
      secrets: File.read(fixture_path("valid_secrets")),
      gitignore: ".kamal/secrets\n"
    )
    assert_empty result.findings,
      "expected no findings on a valid config; got: #{result.findings.map(&:check_id)}"
  end

  def test_non_zero_exit_on_errors
    result = run_runner(yaml: "image: i\n")
    assert_equal 1, result.exit_code(fail_on: :error)
  end

  def test_fail_on_threshold
    result = run_runner(
      yaml: <<~YAML,
        service: a
        image: ghcr.io/x/i
        servers:
          - 1.2.3.4
        builder:
          arch: amd64
        registry:
          server: ghcr.io
          username: u
          password: p
        accessories:
          cache:
            image: redis
            host: 1.2.3.5
      YAML
      secrets: "",
      gitignore: ".kamal/secrets\n"
    )

    assert_empty result.errors,
      "expected no lint errors; got: #{result.errors.map(&:check_id)}"
    refute_empty result.warnings, "expected warnings"

    assert_equal 0, result.exit_code(fail_on: :error)
    assert_equal 1, result.exit_code(fail_on: :warning)
  end

  def test_include_kamal_errors_surfaces_kamal_load_error
    result = nil
    with_project(yaml: "this is not a valid kamal config\n") do
      runner = Kamal::Lint::Runner.new(
        config_file: "config/deploy.yml",
        kamal_version: "2.11.0",
        include_kamal_errors: true
      )
      result = runner.call
    end
    assert_includes result.findings.map(&:check_id), "kamal-parse-error"
  end

  def test_kamal_errors_are_suppressed_by_default
    result = nil
    with_project(yaml: "this is not a valid kamal config\n") do
      runner = Kamal::Lint::Runner.new(
        config_file: "config/deploy.yml",
        kamal_version: "2.11.0"
      )
      result = runner.call
    end
    refute_includes result.findings.map(&:check_id), "kamal-parse-error"
  end
end
