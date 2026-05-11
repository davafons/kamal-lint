# frozen_string_literal: true

require "test_helper"

class TraefikLegacyKeysTest < ActiveSupport::TestCase
  def test_flags_traefik_block
    findings = run_check(
      Kamal::Lint::Checks::TraefikLegacyKeys,
      yaml: "image: i\ntraefik:\n  ssl_redirect: true\n"
    )
    assert_equal 1, findings.size
    assert_equal :warning, findings.first.severity
  end

  def test_silent_without_traefik
    assert_empty run_check(Kamal::Lint::Checks::TraefikLegacyKeys, yaml: "image: i\n")
  end
end
