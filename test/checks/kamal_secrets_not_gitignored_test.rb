# frozen_string_literal: true

require "test_helper"

class KamalSecretsNotGitignoredTest < ActiveSupport::TestCase
  def test_flags_unignored_secrets
    findings = run_check(
      Kamal::Lint::Checks::KamalSecretsNotGitignored,
      yaml: "service: a\nimage: i\n",
      secrets: "K=v\n"
    )
    assert_equal 1, findings.size
  end

  def test_silent_when_gitignored
    result = run_runner(
      yaml: "service: a\nimage: i\n",
      secrets: "K=v\n",
      gitignore: ".kamal/secrets\n"
    )
    ids = result.findings.map(&:check_id)
    refute_includes ids, "kamal-secrets-not-gitignored"
  end

  def test_silent_when_no_secrets_file
    findings = run_check(
      Kamal::Lint::Checks::KamalSecretsNotGitignored,
      yaml: "service: a\nimage: i\n"
    )
    assert_empty findings
  end

  def test_autofix_appends_to_gitignore
    run_runner(
      yaml: "service: a\nimage: i\nservers:\n  - 1.2.3.4\n",
      secrets: "K=v\n",
      gitignore: "/tmp/\n",
      fix: true
    ) do
      assert_includes File.read(".gitignore"), ".kamal/secrets"
    end
  end
end
