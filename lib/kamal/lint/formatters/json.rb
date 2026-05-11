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
              infos: result.infos.size
            }
          }
          @io.puts JSON.pretty_generate(payload)
        end
      end
    end
  end
end
