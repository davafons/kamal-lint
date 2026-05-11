# frozen_string_literal: true

require "test_helper"

class HumanFormatterTest < ActiveSupport::TestCase
  def setup
    @io = StringIO.new
    @formatter = Kamal::Lint::Formatters::Human.new(io: @io, color: false)
    @findings = [
      Kamal::Lint::Finding.new(
        check_id: "secret-not-declared", severity: :error, message: "missing",
        file: "config/deploy.yml", line: 3, column: 1
      ),
      Kamal::Lint::Finding.new(
        check_id: "traefik-legacy-keys", severity: :warning, message: "traefik",
        file: "config/deploy.yml", line: 10, column: 1
      )
    ]
    @ctx = build_context
  end

  def test_renders_header_findings_summary
    result = Kamal::Lint::Result.new(findings: @findings, context: @ctx, destinations: [ nil ])
    @formatter.render(result)
    out = @io.string

    assert_includes out, "kamal-lint"
    assert_includes out, "kamal 2.11.0"
    assert_includes out, "config/deploy.yml:3"
    assert_includes out, "config/deploy.yml:10"
    assert_includes out, "[secret-not-declared]"
    assert_includes out, "Summary:"
    assert_includes out, "1 error"
    assert_includes out, "1 warning"
  end

  def test_renders_all_clear
    clear = Kamal::Lint::Result.new(findings: [], context: @ctx, destinations: [ nil ])
    @formatter.render(clear)
    assert_includes @io.string, "No issues found"
  end

  def test_groups_findings_by_destination
    findings = [
      Kamal::Lint::Finding.new(
        check_id: "base-issue", severity: :error, message: "base",
        file: "config/deploy.yml", line: 1, column: 1, destination: nil
      ),
      Kamal::Lint::Finding.new(
        check_id: "prod-issue", severity: :error, message: "prod-only",
        file: "config/deploy.production.yml", line: 3, column: 1,
        destination: "production"
      )
    ]
    result = Kamal::Lint::Result.new(
      findings: findings, context: @ctx,
      destinations: [ nil, "production", "staging" ]
    )
    @formatter.render(result)
    out = @io.string

    assert_includes out, "[base]"
    assert_includes out, "[production]"
    assert_includes out, "[staging]"
    assert_match(/\[staging\][^\n]*\n.*No issues found/m, out)
    assert_includes out, "across 3 configs"
  end
end
