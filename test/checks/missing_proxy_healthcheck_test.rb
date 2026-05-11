# frozen_string_literal: true

require "test_helper"

class MissingProxyHealthcheckTest < ActiveSupport::TestCase
  def test_flags_proxy_without_healthcheck
    findings = run_check(
      Kamal::Lint::Checks::MissingProxyHealthcheck,
      yaml: "image: i\nproxy:\n  host: example.com\n"
    )
    assert_equal 1, findings.size
  end

  def test_silent_with_healthcheck
    findings = run_check(
      Kamal::Lint::Checks::MissingProxyHealthcheck,
      yaml: "image: i\nproxy:\n  host: example.com\n  healthcheck:\n    path: /up\n"
    )
    assert_empty findings
  end

  def test_silent_without_proxy
    assert_empty run_check(Kamal::Lint::Checks::MissingProxyHealthcheck, yaml: "image: i\n")
  end
end
