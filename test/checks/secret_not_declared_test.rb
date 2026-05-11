# frozen_string_literal: true

require "test_helper"

class SecretNotDeclaredTest < ActiveSupport::TestCase
  def test_flags_undeclared_env_secret
    findings = run_check(
      Kamal::Lint::Checks::SecretNotDeclared,
      yaml: <<~YAML,
        service: a
        image: i
        env:
          secret:
            - DECLARED
            - UNDECLARED
      YAML
      secrets: "DECLARED=x\n"
    )
    assert_equal 1, findings.size
    assert_includes findings.first.message, "UNDECLARED"
    assert_equal 6, findings.first.line
  end

  def test_flags_accessory_env_secret
    findings = run_check(
      Kamal::Lint::Checks::SecretNotDeclared,
      yaml: <<~YAML,
        service: a
        image: i
        accessories:
          db:
            image: postgres
            env:
              secret:
                - DB_PASSWORD
      YAML
      secrets: ""
    )
    assert_includes findings.map(&:message).join, "DB_PASSWORD"
  end

  def test_silent_when_all_declared
    findings = run_check(
      Kamal::Lint::Checks::SecretNotDeclared,
      yaml: "service: a\nimage: i\nenv:\n  secret:\n    - OK\n",
      secrets: "OK=1\n"
    )
    assert_empty findings
  end

  def test_silent_when_no_secrets_block
    findings = run_check(
      Kamal::Lint::Checks::SecretNotDeclared,
      yaml: "service: a\nimage: i\n",
      secrets: ""
    )
    assert_empty findings
  end
end
