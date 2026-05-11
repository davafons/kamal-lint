# frozen_string_literal: true

require "test_helper"

class GithubFormatterTest < ActiveSupport::TestCase
  def setup
    @io = StringIO.new
    @formatter = Kamal::Lint::Formatters::Github.new(io: @io)
    @ctx = build_context
  end

  def test_emits_workflow_commands_per_severity
    findings = [
      Kamal::Lint::Finding.new(check_id: "e", severity: :error, message: "boom",
        file: "config/deploy.yml", line: 4, column: 1),
      Kamal::Lint::Finding.new(check_id: "w", severity: :warning, message: "hmm",
        file: "config/deploy.yml", line: 7, column: 1),
      Kamal::Lint::Finding.new(check_id: "i", severity: :info, message: "fyi",
        file: "config/deploy.yml", line: 9, column: 1)
    ]
    result = Kamal::Lint::Result.new(findings: findings, context: @ctx)
    @formatter.render(result)
    out = @io.string

    assert_includes out, "::error file=config/deploy.yml,line=4,col=1,title=kamal-lint%3A e::boom"
    assert_includes out, "::warning file=config/deploy.yml,line=7,col=1,title=kamal-lint%3A w::hmm"
    assert_includes out, "::notice file=config/deploy.yml,line=9,col=1,title=kamal-lint%3A i::fyi"
  end

  def test_escapes_message_chars
    finding = Kamal::Lint::Finding.new(
      check_id: "x", severity: :error, message: "a%b\nc\rd",
      file: "f", line: 1, column: 1
    )
    result = Kamal::Lint::Result.new(findings: [ finding ], context: @ctx)
    @formatter.render(result)
    assert_includes @io.string, "a%25b%0Ac%0Dd"
  end
end
