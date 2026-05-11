# frozen_string_literal: true

require "test_helper"

class RegistryWithoutExplicitServerTest < ActiveSupport::TestCase
  def test_flags_when_server_missing
    findings = run_check(
      Kamal::Lint::Checks::RegistryWithoutExplicitServer,
      yaml: "image: someorg/myapp\nregistry:\n  username: u\n  password: p\n"
    )
    assert_equal 1, findings.size
  end

  def test_silent_when_server_set
    findings = run_check(
      Kamal::Lint::Checks::RegistryWithoutExplicitServer,
      yaml: "image: ghcr.io/org/myapp\nregistry:\n  server: ghcr.io\n  username: u\n"
    )
    assert_empty findings
  end

  def test_silent_when_image_has_registry_prefix
    findings = run_check(
      Kamal::Lint::Checks::RegistryWithoutExplicitServer,
      yaml: "image: ghcr.io/org/myapp\nregistry:\n  username: u\n"
    )
    assert_empty findings
  end
end
