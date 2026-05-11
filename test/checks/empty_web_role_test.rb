# frozen_string_literal: true

require "test_helper"

class EmptyWebRoleTest < ActiveSupport::TestCase
  def test_flags_missing_servers
    assert_equal 1, run_check(Kamal::Lint::Checks::EmptyWebRole, yaml: "image: i\n").size
  end

  def test_flags_empty_servers_array
    assert_equal 1, run_check(Kamal::Lint::Checks::EmptyWebRole, yaml: "image: i\nservers: []\n").size
  end

  def test_flags_all_roles_empty
    findings = run_check(
      Kamal::Lint::Checks::EmptyWebRole,
      yaml: "image: i\nservers:\n  web: []\n  workers: []\n"
    )
    assert_equal 1, findings.size
  end

  def test_silent_when_role_has_hosts
    findings = run_check(
      Kamal::Lint::Checks::EmptyWebRole,
      yaml: "image: i\nservers:\n  web:\n    - 1.2.3.4\n"
    )
    assert_empty findings
  end
end
