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
    assert_predicate findings.first, :autofixable?
  end

  def test_silent_without_traefik
    assert_empty run_check(Kamal::Lint::Checks::TraefikLegacyKeys, yaml: "image: i\n")
  end

  def test_autofix_rewrites_traefik_to_proxy
    result = run_runner(
      yaml: <<~YAML,
        service: x
        image: x
        servers:
          - 1.2.3.4
        traefik:
          host: app.example.com
          ssl_redirect: true
      YAML
      secrets: "",
      gitignore: ".kamal/secrets\n",
      fix: true
    ) do
      rewritten = YAML.safe_load_file("config/deploy.yml")
      refute rewritten.key?("traefik")
      assert_equal "app.example.com", rewritten["proxy"]["host"]
      assert_equal true, rewritten["proxy"]["ssl"]
    end
    assert_includes result.fixed.map(&:check_id), "traefik-legacy-keys"
  end
end
