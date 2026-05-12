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

  def test_destination_secrets_are_merged
    # The base secrets file doesn't declare REGISTRY_PASS, but the
    # destination-specific .kamal/secrets.prod does — and Kamal sources both
    # at deploy time, so the linter should too.
    findings = run_check(
      Kamal::Lint::Checks::BuilderRegistrySecretUndeclared,
      yaml: "image: i\nregistry:\n  password:\n    - REGISTRY_PASS\n",
      destination: "prod",
      destination_yaml: "service: x\n",
      secrets: "",
      destination_secrets: "REGISTRY_PASS=$(some-cmd)\n"
    )
    assert_empty findings
  end
end
