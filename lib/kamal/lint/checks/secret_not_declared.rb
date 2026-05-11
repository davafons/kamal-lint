# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class SecretNotDeclared < Check
        id "secret-not-declared"
        severity :error
        since "2.0.0"
        title "env.secret references a key not declared in .kamal/secrets"

        def call
          findings = []
          declared = context.secrets

          referenced_secret_keys.each do |path, name|
            next if declared.include?(name)

            findings << finding(
              message: "env.secret references `#{name}` but it isn't declared in .kamal/secrets",
              line: context.line_for(path)
            )
          end

          findings
        end

        private

        def referenced_secret_keys
          refs = []
          collect_secrets(parsed["env"], [ "env" ], refs)
          (parsed["accessories"] || {}).each do |name, accessory|
            next unless accessory.is_a?(Hash)

            collect_secrets(accessory["env"], [ "accessories", name, "env" ], refs)
          end
          refs
        end

        def collect_secrets(env_block, prefix, refs)
          return unless env_block.is_a?(Hash)

          list = env_block["secret"]
          return unless list.is_a?(Array)

          list.each_with_index do |name, idx|
            next unless name.is_a?(String)

            refs << [ prefix + [ "secret", idx.to_s ], name ]
          end
        end
      end

      Lint.registry.register(SecretNotDeclared)
    end
  end
end
