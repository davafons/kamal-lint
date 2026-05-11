# frozen_string_literal: true

module Kamal
  module Lint
    module Formatters
      # GitHub Actions workflow command output.
      # See: https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions
      class Github
        LEVEL = {
          error: "error",
          warning: "warning",
          info: "notice"
        }.freeze

        def initialize(io: $stdout)
          @io = io
        end

        def render(result)
          result.findings.each do |finding|
            level = LEVEL[finding.severity] || "notice"
            attrs = {
              file: finding.file,
              line: finding.line,
              col: finding.column,
              title: title_for(finding)
            }.compact

            attr_str = attrs.map { |k, v| "#{k}=#{escape_property(v.to_s)}" }.join(",")
            message = escape_message(finding.message)
            @io.puts "::#{level} #{attr_str}::#{message}"
          end
        end

        private

        def title_for(finding)
          if finding.destination
            "kamal-lint [#{finding.destination}]: #{finding.check_id}"
          else
            "kamal-lint: #{finding.check_id}"
          end
        end

        def escape_message(value)
          value.to_s.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A")
        end

        def escape_property(value)
          value.to_s.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A").gsub(":", "%3A").gsub(",", "%2C")
        end
      end
    end
  end
end
