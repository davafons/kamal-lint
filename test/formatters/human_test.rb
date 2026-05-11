# frozen_string_literal: true

require "test_helper"

class HumanFormatterTest < ActiveSupport::TestCase
  def setup
    @io = StringIO.new
    @formatter = Kamal::Lint::Formatters::Human.new(io: @io, color: false)
    @findings = [
      Kamal::Lint::Finding.new(
        check_id: "secret-not-declared", severity: :error, message: "missing",
        file: "config/deploy.yml", line: 3, column: 1, autofix: nil
      ),
      Kamal::Lint::Finding.new(
        check_id: "traefik-legacy-keys", severity: :warning, message: "traefik",
        file: "config/deploy.yml", line: 10, column: 1, autofix: ->(_) { true }
      )
    ]
    @ctx = build_context
  end

  def test_renders_header_findings_summary
    result = Kamal::Lint::Result.new(findings: @findings, context: @ctx, fixed: [])
    @formatter.render(result)
    out = @io.string

    assert_includes out, "kamal-lint"
    assert_includes out, "kamal 2.11.0"
    assert_includes out, "config/deploy.yml:3"
    assert_includes out, "config/deploy.yml:10"
    assert_includes out, "(autofixable)"
    assert_includes out, "[secret-not-declared]"
    assert_includes out, "Summary:"
    assert_includes out, "1 error"
    assert_includes out, "1 warning"
  end

  def test_renders_all_clear
    clear = Kamal::Lint::Result.new(findings: [], context: @ctx, fixed: [])
    @formatter.render(clear)
    assert_includes @io.string, "No issues found"
  end

  def test_fix_summary
    fixed_result = Kamal::Lint::Result.new(findings: @findings, context: @ctx, fixed: [ @findings.last ])
    @formatter.render(fixed_result)
    @formatter.render_fix_summary(fixed_result)
    assert_includes @io.string, "Applied autofixes"
    assert_includes @io.string, "traefik-legacy-keys"
  end
end
