# frozen_string_literal: true

require "test_helper"

class ImageRegistryMismatchTest < ActiveSupport::TestCase
  def test_flags_mismatch
    findings = run_check(
      Kamal::Lint::Checks::ImageRegistryMismatch,
      yaml: "image: someorg/myapp\nregistry:\n  server: ghcr.io\n"
    )
    assert_equal 1, findings.size
    assert_includes findings.first.message, "ghcr.io"
  end

  def test_silent_when_aligned
    findings = run_check(
      Kamal::Lint::Checks::ImageRegistryMismatch,
      yaml: "image: ghcr.io/davafons/myapp\nregistry:\n  server: ghcr.io\n"
    )
    assert_empty findings
  end

  def test_silent_without_server
    findings = run_check(
      Kamal::Lint::Checks::ImageRegistryMismatch,
      yaml: "image: someorg/myapp\nregistry:\n  username: u\n"
    )
    assert_empty findings
  end

  def test_silent_when_server_is_docker_hub
    %w[docker.io index.docker.io registry.hub.docker.com].each do |hub|
      findings = run_check(
        Kamal::Lint::Checks::ImageRegistryMismatch,
        yaml: "image: someorg/myapp\nregistry:\n  server: #{hub}\n"
      )
      assert_empty findings, "expected no findings for Docker Hub host `#{hub}`"
    end
  end
end
