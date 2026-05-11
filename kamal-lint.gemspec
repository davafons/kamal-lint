# frozen_string_literal: true

require_relative "lib/kamal/lint/version"

Gem::Specification.new do |spec|
  spec.name = "kamal-lint"
  spec.version = Kamal::Lint::VERSION
  spec.authors = [ "David Afonso" ]
  spec.email = [ "davafons@gmail.com" ]

  spec.summary = "Static linter for Kamal deploy.yml"
  spec.description = "Catches cross-section bugs and smells in Kamal's config/deploy.yml that Kamal itself silently allows: undeclared secrets, accessory/role mismatches, registry inconsistencies, and more. Supports auto-fix for safe rewrites and outputs human, JSON, or GitHub Actions formats."
  spec.homepage = "https://github.com/davafons/kamal-lint"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*",
    "bin/kamal-lint",
    "action.yml",
    "README.md",
    "CHANGELOG.md",
    "MIT-LICENSE"
  ]
  spec.bindir = "bin"
  spec.executables = [ "kamal-lint" ]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "kamal", ">= 2.0", "< 3.0"
  spec.add_dependency "thor", "~> 1.3"

  spec.add_development_dependency "debug"
  spec.add_development_dependency "minitest", "< 6"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "railties"
end
