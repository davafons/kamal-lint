# frozen_string_literal: true

require "bundler/setup"
require "active_support/test_case"
require "active_support/testing/autorun"
require "active_support/testing/stream"
require "mocha/minitest"
require "minitest/autorun"

require "fileutils"
require "tmpdir"
require "stringio"
require "tempfile"
require "json"
require "yaml"

require "kamal/lint"

class ActiveSupport::TestCase
  include ActiveSupport::Testing::Stream

  private

  def fixture_path(*parts)
    File.join(__dir__, "fixtures", *parts)
  end

  def with_project(yaml:, secrets: nil, gitignore: nil, destination_yaml: nil, destination_name: nil)
    Dir.mktmpdir("kamal-lint-test") do |dir|
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config", "deploy.yml"), yaml)
      if destination_yaml && destination_name
        File.write(File.join(dir, "config", "deploy.#{destination_name}.yml"), destination_yaml)
      end
      if secrets
        FileUtils.mkdir_p(File.join(dir, ".kamal"))
        File.write(File.join(dir, ".kamal", "secrets"), secrets)
      end
      File.write(File.join(dir, ".gitignore"), gitignore) if gitignore
      Dir.chdir(dir) { yield dir }
    end
  end

  def run_check(check_class, yaml:, secrets: nil, destination: nil)
    findings = nil
    with_project(yaml: yaml, secrets: secrets) do
      ctx = Kamal::Lint::Loader.load(
        config_file: "config/deploy.yml",
        destination: destination,
        kamal_version: "2.11.0"
      )
      findings = Array(check_class.new(ctx).call)
    end
    findings
  end

  def run_runner(yaml:, secrets: nil, gitignore: nil, fix: false, destination: nil)
    result = nil
    with_project(yaml: yaml, secrets: secrets, gitignore: gitignore) do
      runner = Kamal::Lint::Runner.new(
        config_file: "config/deploy.yml",
        destination: destination,
        kamal_version: "2.11.0",
        fix: fix
      )
      result = runner.call
      yield result if block_given?
    end
    result
  end

  def build_context(**overrides)
    defaults = {
      config_file: "config/deploy.yml",
      destination: nil,
      working_dir: "/tmp",
      parsed: {},
      base_parsed: {},
      override_parsed: nil,
      source_lines: [],
      line_index: {},
      secrets: [],
      secrets_path: "",
      gitignore_path: "",
      kamal_version: "2.11.0",
      kamal_loaded: true,
      kamal_load_error: nil
    }
    Kamal::Lint::Context.new(**defaults.merge(overrides))
  end
end
