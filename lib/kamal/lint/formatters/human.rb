# frozen_string_literal: true

module Kamal
  module Lint
    module Formatters
      class Human
        COLORS = {
          reset: "\e[0m",
          bold: "\e[1m",
          dim: "\e[2m",
          red: "\e[31m",
          yellow: "\e[33m",
          green: "\e[32m",
          blue: "\e[34m",
          magenta: "\e[35m",
          cyan: "\e[36m",
          gray: "\e[90m"
        }.freeze

        SEVERITY_GLYPH = {
          error: "✖",
          warning: "⚠",
          info: "•"
        }.freeze

        SEVERITY_COLOR = {
          error: :red,
          warning: :yellow,
          info: :blue
        }.freeze

        def initialize(io: $stdout, color: nil)
          @io = io
          @color = color.nil? ? io.tty? : color
        end

        def render(result)
          render_header(result)

          if result.findings.empty?
            @io.puts c(:green, "  ✓ No issues found.")
            return
          end

          result.findings
            .sort_by { |f| [ SEVERITIES.index(f.severity), f.line || 0 ] }
            .each { |finding| render_finding(finding) }

          render_summary(result)
        end

        def render_fix_summary(result)
          return if result.fixed.empty?

          @io.puts
          @io.puts c(:bold, "Applied autofixes:")
          result.fixed.each do |finding|
            @io.puts "  #{c(:green, "✓")} [#{finding.check_id}] #{finding.message}"
          end
        end

        private

        def render_header(result)
          version = Kamal::Lint::VERSION
          kamal = result.context.kamal_version || "?"
          @io.puts "#{c(:bold, "kamal-lint")} #{c(:dim, version)} · kamal #{c(:cyan, kamal)} detected"
          if (dest = result.context.destination)
            @io.puts "  destination: #{c(:cyan, dest)}"
          end
          @io.puts "  config:      #{c(:cyan, result.context.file_for_finding)}"
          @io.puts
        end

        def render_finding(finding)
          loc = "#{finding.file}:#{finding.line || "?"}"
          glyph = SEVERITY_GLYPH[finding.severity] || "?"
          color = SEVERITY_COLOR[finding.severity] || :gray
          sev = finding.severity.to_s.ljust(7)
          fix_hint = finding.autofixable? ? c(:dim, " (autofixable)") : ""

          @io.puts "#{c(color, glyph)} #{c(:bold, sev)} #{c(:gray, loc)}#{fix_hint}"
          @io.puts "    #{finding.message}"
          @io.puts "    #{c(:dim, "[#{finding.check_id}]")}"
          @io.puts
        end

        def render_summary(result)
          errors = result.errors.size
          warnings = result.warnings.size
          infos = result.infos.size
          autofixable = result.findings.count(&:autofixable?)

          parts = []
          parts << "#{c(:red, errors.to_s)} error#{plural(errors)}" if errors > 0
          parts << "#{c(:yellow, warnings.to_s)} warning#{plural(warnings)}" if warnings > 0
          parts << "#{c(:blue, infos.to_s)} info" if infos > 0
          parts << "#{c(:dim, "#{autofixable} autofixable")}" if autofixable > 0

          @io.puts c(:bold, "Summary: ") + parts.join(", ")
        end

        def plural(n)
          n == 1 ? "" : "s"
        end

        def c(color, text)
          return text unless @color

          code = COLORS[color]
          return text unless code

          "#{code}#{text}#{COLORS[:reset]}"
        end
      end
    end
  end
end
