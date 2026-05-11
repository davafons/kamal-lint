# frozen_string_literal: true

require "test_helper"

class AccessoryImageLatestTest < ActiveSupport::TestCase
  def test_flags_latest_tag
    findings = run_check(
      Kamal::Lint::Checks::AccessoryImageLatest,
      yaml: "image: i\naccessories:\n  db:\n    image: postgres:latest\n"
    )
    assert_equal 1, findings.size
    assert_includes findings.first.message, ":latest"
  end

  def test_flags_untagged
    findings = run_check(
      Kamal::Lint::Checks::AccessoryImageLatest,
      yaml: "image: i\naccessories:\n  db:\n    image: redis\n"
    )
    assert_equal 1, findings.size
    assert_includes findings.first.message, "no tag"
  end

  def test_silent_when_pinned
    findings = run_check(
      Kamal::Lint::Checks::AccessoryImageLatest,
      yaml: "image: i\naccessories:\n  db:\n    image: postgres:16.4\n"
    )
    assert_empty findings
  end
end
