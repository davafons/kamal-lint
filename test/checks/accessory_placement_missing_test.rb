# frozen_string_literal: true

require "test_helper"

class AccessoryPlacementMissingTest < ActiveSupport::TestCase
  def test_flags_when_no_placement
    findings = run_check(
      Kamal::Lint::Checks::AccessoryPlacementMissing,
      yaml: "image: i\naccessories:\n  db:\n    image: postgres\n"
    )
    assert_equal 1, findings.size
    assert_includes findings.first.message, "db"
  end

  def test_accepts_host
    assert_empty run_check(
      Kamal::Lint::Checks::AccessoryPlacementMissing,
      yaml: "image: i\naccessories:\n  db:\n    image: p\n    host: 1.2.3.4\n"
    )
  end

  def test_accepts_hosts_array
    assert_empty run_check(
      Kamal::Lint::Checks::AccessoryPlacementMissing,
      yaml: "image: i\naccessories:\n  db:\n    image: p\n    hosts:\n      - 1.2.3.4\n"
    )
  end

  def test_accepts_roles
    assert_empty run_check(
      Kamal::Lint::Checks::AccessoryPlacementMissing,
      yaml: "image: i\naccessories:\n  db:\n    image: p\n    roles:\n      - web\n"
    )
  end
end
