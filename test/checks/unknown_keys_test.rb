# frozen_string_literal: true

require "test_helper"

class UnknownKeysTest < ActiveSupport::TestCase
  def test_silent_on_known_top_level_keys
    findings = run_check(
      Kamal::Lint::Checks::UnknownKeys,
      yaml: <<~YAML
        service: myapp
        image: my-image
        servers:
          - 1.1.1.1
      YAML
    )
    assert_empty findings
  end

  def test_silent_on_known_proxy_keys
    findings = run_check(
      Kamal::Lint::Checks::UnknownKeys,
      yaml: <<~YAML
        image: i
        proxy:
          ssl: true
          hosts:
            - example.com
          healthcheck:
            path: /up
      YAML
    )
    assert_empty findings
  end

  def test_flags_misplaced_top_level_key_under_proxy
    findings = run_check(
      Kamal::Lint::Checks::UnknownKeys,
      yaml: <<~YAML
        image: i
        proxy:
          ssl: true
          hosts: [example.com]
          deploy_timeout: 600
      YAML
    )
    assert_equal 1, findings.size
    msg = findings.first.message
    assert_match(/proxy\.deploy_timeout/, msg)
    assert_match(/top-level Kamal key/, msg)
  end

  def test_flags_unknown_proxy_key_with_generic_message
    findings = run_check(
      Kamal::Lint::Checks::UnknownKeys,
      yaml: <<~YAML
        image: i
        proxy:
          mystery_key: 42
      YAML
    )
    assert_equal 1, findings.size
    msg = findings.first.message
    assert_match(/unknown key `proxy.mystery_key`/, msg)
  end

  def test_flags_unknown_top_level_key
    findings = run_check(
      Kamal::Lint::Checks::UnknownKeys,
      yaml: <<~YAML
        image: i
        nonsense: 42
      YAML
    )
    assert_equal 1, findings.size
    assert_match(/unknown key `nonsense`/, findings.first.message)
  end

  def test_silent_on_x_extension_keys
    findings = run_check(
      Kamal::Lint::Checks::UnknownKeys,
      yaml: <<~YAML
        image: i
        x-anchor:
          some: value
        proxy:
          x-shared: &shared
            ssl: true
          ssl: true
      YAML
    )
    assert_empty findings
  end

  def test_silent_when_proxy_not_a_hash
    findings = run_check(
      Kamal::Lint::Checks::UnknownKeys,
      yaml: "image: i\nproxy: true\n"
    )
    assert_empty findings
  end
end
