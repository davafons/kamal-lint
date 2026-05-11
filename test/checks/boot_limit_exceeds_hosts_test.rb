# frozen_string_literal: true

require "test_helper"

class BootLimitExceedsHostsTest < ActiveSupport::TestCase
  def test_flags_excessive_limit
    findings = run_check(
      Kamal::Lint::Checks::BootLimitExceedsHosts,
      yaml: "image: i\nservers:\n  - 1.2.3.4\nboot:\n  limit: 5\n"
    )
    assert_equal 1, findings.size
  end

  def test_silent_when_limit_within
    findings = run_check(
      Kamal::Lint::Checks::BootLimitExceedsHosts,
      yaml: "image: i\nservers:\n  - 1.2.3.4\n  - 1.2.3.5\nboot:\n  limit: 2\n"
    )
    assert_empty findings
  end

  def test_silent_without_limit
    findings = run_check(
      Kamal::Lint::Checks::BootLimitExceedsHosts,
      yaml: "image: i\nservers:\n  - 1.2.3.4\n"
    )
    assert_empty findings
  end
end
