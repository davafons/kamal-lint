# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class SecretInEnvClear < Check
        id "secret-in-env-clear"
        severity :warning
        since "2.0.0"
        title "Value in `env.clear` looks like a secret"

        SECRET_KEY_PATTERN = /(\A|_)(KEY|SECRET|TOKEN|PASSWORD|PWD|CREDENTIALS?)(_|\z)/i

        def call
          findings = []
          scan_env(parsed["env"], [ "env" ], findings)
          (parsed["accessories"] || {}).each do |name, accessory|
            scan_env(accessory["env"], [ "accessories", name, "env" ], findings) if accessory.is_a?(Hash)
          end
          findings
        end

        private

        def scan_env(env, prefix, findings)
          return unless env.is_a?(Hash)

          clear = env["clear"]
          return unless clear.is_a?(Hash)

          clear.each do |key, _value|
            next unless key.is_a?(String) && key.match?(SECRET_KEY_PATTERN)

            findings << finding(
              message: "env.clear contains `#{key}` which looks like a secret; move it to env.secret + .kamal/secrets",
              line: context.line_for(prefix + [ "clear", key ])
            )
          end
        end
      end

      Lint.registry.register(SecretInEnvClear)
    end
  end
end
