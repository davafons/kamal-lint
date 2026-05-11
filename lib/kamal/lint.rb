# frozen_string_literal: true

require_relative "lint/version"

module Kamal
  module Lint
    SEVERITIES = %i[error warning info].freeze

    class Error < StandardError; end

    class ConfigNotFoundError < Error; end

    def self.registry
      Registry.default
    end

    def self.formatters
      FORMATTERS
    end
  end
end

require_relative "lint/finding"
require_relative "lint/check"
require_relative "lint/registry"
require_relative "lint/secrets_file"
require_relative "lint/servers_helper"
require_relative "lint/loader"
require_relative "lint/kamal_version"
require_relative "lint/runner"

require_relative "lint/formatters/human"
require_relative "lint/formatters/json"
require_relative "lint/formatters/github"

module Kamal
  module Lint
    FORMATTERS = {
      "human" => Formatters::Human,
      "json" => Formatters::Json,
      "github" => Formatters::Github
    }.freeze
  end
end

require_relative "lint/checks/secret_not_declared"
require_relative "lint/checks/accessory_role_undefined"
require_relative "lint/checks/role_hosts_empty"
require_relative "lint/checks/image_registry_mismatch"
require_relative "lint/checks/builder_registry_secret_undeclared"
require_relative "lint/checks/ssl_without_host"
require_relative "lint/checks/empty_web_role"
require_relative "lint/checks/traefik_legacy_keys"
require_relative "lint/checks/boot_limit_exceeds_hosts"
require_relative "lint/checks/accessory_placement_missing"
require_relative "lint/checks/missing_service_name"
require_relative "lint/checks/kamal_secrets_not_gitignored"
require_relative "lint/checks/secret_in_env_clear"
require_relative "lint/checks/missing_proxy_healthcheck"
require_relative "lint/checks/accessory_image_latest"
require_relative "lint/checks/registry_without_explicit_server"

require_relative "lint/cli"
