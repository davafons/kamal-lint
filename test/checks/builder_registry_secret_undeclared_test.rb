# frozen_string_literal: true

require "test_helper"

class BuilderRegistrySecretUndeclaredTest < ActiveSupport::TestCase
  def test_flags_undeclared_password
    findings = run_check(
      Kamal::Lint::Checks::BuilderRegistrySecretUndeclared,
      yaml: <<~YAML,
        image: i
        registry:
          username:
            - REGISTRY_USER
          password:
            - REGISTRY_PASS
      YAML
      secrets: "REGISTRY_USER=u\n"
    )
    msg = findings.map(&:message).join
    assert_includes msg, "REGISTRY_PASS"
    refute_includes msg, "REGISTRY_USER"
  end

  def test_silent_when_all_declared
    findings = run_check(
      Kamal::Lint::Checks::BuilderRegistrySecretUndeclared,
      yaml: "image: i\nregistry:\n  username:\n    - U\n  password:\n    - P\n",
      secrets: "U=1\nP=2\n"
    )
    assert_empty findings
  end

  def test_silent_for_plain_strings
    findings = run_check(
      Kamal::Lint::Checks::BuilderRegistrySecretUndeclared,
      yaml: "image: i\nregistry:\n  username: literal\n  password: literal\n",
      secrets: ""
    )
    assert_empty findings
  end
end
