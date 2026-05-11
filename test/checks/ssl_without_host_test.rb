# frozen_string_literal: true

require "test_helper"

class SslWithoutHostTest < ActiveSupport::TestCase
  def test_flags_ssl_true_no_host
    findings = run_check(
      Kamal::Lint::Checks::SslWithoutHost,
      yaml: "image: i\nproxy:\n  ssl: true\n"
    )
    assert_equal 1, findings.size
  end

  def test_silent_when_host_set
    findings = run_check(
      Kamal::Lint::Checks::SslWithoutHost,
      yaml: "image: i\nproxy:\n  ssl: true\n  host: example.com\n"
    )
    assert_empty findings
  end

  def test_silent_when_hosts_array
    findings = run_check(
      Kamal::Lint::Checks::SslWithoutHost,
      yaml: "image: i\nproxy:\n  ssl: true\n  hosts:\n    - a.example.com\n"
    )
    assert_empty findings
  end

  def test_silent_when_ssl_false
    findings = run_check(
      Kamal::Lint::Checks::SslWithoutHost,
      yaml: "image: i\nproxy:\n  ssl: false\n"
    )
    assert_empty findings
  end
end
