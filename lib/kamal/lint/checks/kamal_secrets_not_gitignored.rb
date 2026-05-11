# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class KamalSecretsNotGitignored < Check
        id "kamal-secrets-not-gitignored"
        severity :warning
        since "2.0.0"
        autofixable true
        title ".kamal/secrets is not in .gitignore"

        # We only flag when:
        #   - a .kamal/secrets file exists (so there's something to leak), AND
        #   - it is NOT covered by .gitignore (or .gitignore is missing).
        def call
          return [] unless File.exist?(context.secrets_path)
          return [] if gitignored?

          [ finding(
            message: ".kamal/secrets exists but isn't ignored by .gitignore; you risk committing real secrets",
            line: 1,
            autofix: method(:apply_fix)
          ) ]
        end

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

        def apply_fix(ctx)
          path = ctx.gitignore_path
          existing = File.exist?(path) ? File.read(path) : ""
          existing = existing + "\n" unless existing.empty? || existing.end_with?("\n")
          File.write(path, "#{existing}.kamal/secrets\n")
          true
        rescue => _e
          false
        end
      end

      Lint.registry.register(KamalSecretsNotGitignored)
    end
  end
end
