# frozen_string_literal: true

require "test_helper"

class JsonFormatterTest < ActiveSupport::TestCase
  def test_renders_payload
    io = StringIO.new
    formatter = Kamal::Lint::Formatters::Json.new(io: io)
    ctx = build_context(destination: "production")
    findings = [ Kamal::Lint::Finding.new(
      check_id: "x", severity: :error, message: "m",
      file: "f", line: 1, column: 2
    ) ]
    result = Kamal::Lint::Result.new(findings: findings, context: ctx)
    formatter.render(result)
    payload = JSON.parse(io.string)

    assert_equal Kamal::Lint::VERSION, payload["kamal_lint_version"]
    assert_equal "2.11.0", payload["kamal_version"]
    assert_equal "production", payload["destination"]
    assert_equal 1, payload["findings"].size
    assert_equal({ "errors" => 1, "warnings" => 0, "infos" => 0 }, payload["summary"])
  end
end
