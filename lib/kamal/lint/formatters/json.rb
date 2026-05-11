# frozen_string_literal: true

require "json"

module Kamal
  module Lint
    module Formatters
      class Json
        def initialize(io: $stdout)
          @io = io
        end

        def render(result)
          payload = {
            kamal_lint_version: Kamal::Lint::VERSION,
            kamal_version: result.context.kamal_version,
            file: result.context.file_for_finding,
            destination: result.context.destination,
            findings: result.findings.map(&:to_h),
            summary: {
              errors: result.errors.size,
              warnings: result.warnings.size,
              infos: result.infos.size,
              autofixable: result.findings.count(&:autofixable?)
            }
          }
          @io.puts JSON.pretty_generate(payload)
        end

        def render_fix_summary(result)
          return if result.fixed.empty?

          @io.puts JSON.pretty_generate(fixed: result.fixed.map(&:to_h))
        end
      end
    end
  end
end
