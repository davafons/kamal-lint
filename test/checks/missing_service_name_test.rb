# frozen_string_literal: true

require "test_helper"

class MissingServiceNameTest < ActiveSupport::TestCase
  def test_flags_when_missing
    findings = run_check(Kamal::Lint::Checks::MissingServiceName, yaml: "image: i\n")
    assert_equal 1, findings.size
  end

  def test_silent_when_set
    assert_empty run_check(Kamal::Lint::Checks::MissingServiceName, yaml: "service: x\nimage: i\n")
  end
end
