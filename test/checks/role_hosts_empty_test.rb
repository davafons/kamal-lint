# frozen_string_literal: true

require "test_helper"

class RoleHostsEmptyTest < ActiveSupport::TestCase
  def test_flags_empty_role
    findings = run_check(
      Kamal::Lint::Checks::RoleHostsEmpty,
      yaml: <<~YAML
        servers:
          web:
            - 1.2.3.4
          workers: []
      YAML
    )
    assert_includes findings.map(&:message).join, "workers"
  end

  def test_silent_when_all_roles_have_hosts
    findings = run_check(
      Kamal::Lint::Checks::RoleHostsEmpty,
      yaml: "servers:\n  web:\n    - 1.2.3.4\n"
    )
    assert_empty findings
  end

  def test_silent_for_array_form
    findings = run_check(
      Kamal::Lint::Checks::RoleHostsEmpty,
      yaml: "servers:\n  - 1.2.3.4\n"
    )
    assert_empty findings
  end
end
