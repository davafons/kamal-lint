# frozen_string_literal: true

require "test_helper"

class MissingServiceNameTest < ActiveSupport::TestCase
  def test_flags_when_missing
    findings = run_check(Kamal::Lint::Checks::MissingServiceName, yaml: "image: i\n")
    assert_equal 1, findings.size
    assert_predicate findings.first, :autofixable?
  end

  def test_silent_when_set
    assert_empty run_check(Kamal::Lint::Checks::MissingServiceName, yaml: "service: x\nimage: i\n")
  end

  def test_autofix_sets_service_from_cwd
    result = run_runner(
      yaml: "image: i\nservers:\n  - 1.2.3.4\n",
      secrets: "",
      gitignore: ".kamal/secrets\n",
      fix: true
    ) do
      content = YAML.safe_load_file("config/deploy.yml")
      assert_kind_of String, content["service"]
      refute content["service"].empty?
      assert_equal "i", content["image"]
    end
    assert_includes result.fixed.map(&:check_id), "missing-service-name"
  end
end
