# frozen_string_literal: true

require "test_helper"

class AccessoryRoleUndefinedTest < ActiveSupport::TestCase
  def test_flags_undefined_role
    findings = run_check(
      Kamal::Lint::Checks::AccessoryRoleUndefined,
      yaml: <<~YAML
        service: a
        image: i
        servers:
          web:
            - 1.2.3.4
        accessories:
          db:
            image: postgres
            roles:
              - bogus
      YAML
    )
    assert_equal 1, findings.size
    assert_includes findings.first.message, "bogus"
  end

  def test_accepts_defined_roles
    findings = run_check(
      Kamal::Lint::Checks::AccessoryRoleUndefined,
      yaml: <<~YAML
        servers:
          web:
            - 1.2.3.4
          workers:
            - 1.2.3.5
        accessories:
          db:
            image: postgres
            roles:
              - web
              - workers
      YAML
    )
    assert_empty findings
  end

  def test_implicit_web_role
    findings = run_check(
      Kamal::Lint::Checks::AccessoryRoleUndefined,
      yaml: <<~YAML
        servers:
          - 1.2.3.4
        accessories:
          db:
            image: postgres
            roles:
              - web
      YAML
    )
    assert_empty findings
  end
end
