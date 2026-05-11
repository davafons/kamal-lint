# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class BuilderRegistrySecretUndeclared < Check
        id "builder-registry-secret-undeclared"
        severity :error
        since "2.0.0"
        title "registry username/password references a secret not declared in .kamal/secrets"

        def call
          registry = parsed["registry"] || parsed.dig("builder", "registry")
          return [] unless registry.is_a?(Hash)

          declared = context.secrets
          findings = []

          %w[username password].each do |key|
            value = registry[key]
            next unless value.is_a?(Array)

            value.each_with_index do |name, idx|
              next unless name.is_a?(String)
              next if declared.include?(name)

              findings << finding(
                message: "registry #{key} references secret `#{name}` but it isn't declared in .kamal/secrets",
                line: context.line_for([ "registry", key, idx.to_s ]) ||
                      context.line_for([ "builder", "registry", key, idx.to_s ])
              )
            end
          end

          findings
        end
      end

      Lint.registry.register(BuilderRegistrySecretUndeclared)
    end
  end
end
