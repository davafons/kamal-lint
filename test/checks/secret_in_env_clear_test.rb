# frozen_string_literal: true

require "test_helper"

class SecretInEnvClearTest < ActiveSupport::TestCase
  def test_flags_secret_like_keys
    findings = run_check(
      Kamal::Lint::Checks::SecretInEnvClear,
      yaml: <<~YAML
        image: i
        env:
          clear:
            LANG: en_US.UTF-8
            RAILS_MASTER_KEY: leak
            API_TOKEN: leak
            DB_PASSWORD: leak
      YAML
    )
    msg = findings.map(&:message).join
    assert_includes msg, "RAILS_MASTER_KEY"
    assert_includes msg, "API_TOKEN"
    assert_includes msg, "DB_PASSWORD"
    refute_includes msg, "LANG"
  end

  def test_scans_accessory_env
    findings = run_check(
      Kamal::Lint::Checks::SecretInEnvClear,
      yaml: <<~YAML
        image: i
        accessories:
          db:
            image: postgres
            env:
              clear:
                DB_PASSWORD: hardcoded
      YAML
    )
    assert_equal 1, findings.size
  end

  def test_silent_for_innocuous_keys
    findings = run_check(
      Kamal::Lint::Checks::SecretInEnvClear,
      yaml: "image: i\nenv:\n  clear:\n    LANG: en_US.UTF-8\n    TZ: UTC\n"
    )
    assert_empty findings
  end
end
