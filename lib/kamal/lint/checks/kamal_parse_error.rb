# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      # Opt-in: surfaces errors from Kamal's own loader as findings.
      # Off by default because Kamal's parse-level validation is what
      # `kamal config` is for — the linter's value-add is the cross-section
      # checks. Enabled with `--include-kamal-errors`.
      class KamalParseError < Check
        id "kamal-parse-error"
        severity :error
        since "2.0.0"
        title "Kamal's own loader rejected this config"

        def call
          return [] unless context.include_kamal_errors
          return [] unless context.kamal_load_error

          [ finding(
            message: "kamal could not load this config: #{context.kamal_load_error.message}",
            line: 1
          ) ]
        end
      end

      Lint.registry.register(KamalParseError)
    end
  end
end
