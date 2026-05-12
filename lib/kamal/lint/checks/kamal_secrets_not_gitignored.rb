# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class KamalSecretsNotGitignored < Check
        id "kamal-secrets-not-gitignored"
        severity :warning
        since "2.0.0"
        title ".kamal/secrets is not in .gitignore"

        # We only flag when:
        #   - a .kamal/secrets file exists (so there's something to leak), AND
        #   - it is NOT covered by .gitignore (or .gitignore is missing), AND
        #   - it contains at least one raw literal value (not just shell
        #     substitutions like `$(cmd)`, `${VAR}`, or `$VAR`). Files that
        #     only reference secrets via substitution are safe to commit.
        def call
          return [] unless File.exist?(context.secrets_path)
          return [] if gitignored?
          return [] unless contains_literal_secret?

          [ finding(
            message: ".kamal/secrets exists but isn't ignored by .gitignore; add `.kamal/secrets` to .gitignore",
            line: 1
          ) ]
        end

        private

        def gitignored?
          return false unless File.exist?(context.gitignore_path)

          File.foreach(context.gitignore_path).any? do |line|
            stripped = line.strip
            next false if stripped.empty? || stripped.start_with?("#")

            stripped == ".kamal/secrets" ||
              stripped == "/.kamal/secrets" ||
              stripped == ".kamal/*" ||
              stripped == ".kamal/" ||
              stripped == ".kamal"
          end
        end

        # A value is "safe" when it sources its content from outside the file:
        #   FOO=$(cmd ...)            # command substitution
        #   FOO=${VAR:-fallback}      # parameter expansion
        #   FOO=$VAR                  # plain variable
        #   FOO=                      # empty
        # Anything else (literal token, quoted string, fragment) is treated as
        # a raw secret and triggers the finding.
        SAFE_VALUE = /\A
          \s*                         # leading whitespace
          (?:
            \z                          # empty
            |
            \$\(.*\)                    # $( ... )
            |
            \$\{.*\}                    # ${ ... }
            |
            \$[A-Za-z_][A-Za-z0-9_]*    # $VAR
          )
          \s*\z
        /x

        def contains_literal_secret?
          return false unless File.exist?(context.secrets_path)

          File.foreach(context.secrets_path).any? do |raw|
            line = raw.strip
            next false if line.empty? || line.start_with?("#")

            line = line.sub(/\Aexport\s+/, "")
            _name, eq, value = line.partition("=")
            next false if eq.empty?

            !SAFE_VALUE.match?(value)
          end
        end
      end

      Lint.registry.register(KamalSecretsNotGitignored)
    end
  end
end
