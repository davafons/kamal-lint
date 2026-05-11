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

        SEVERITY_GLYPH = { error: "✖", warning: "⚠", info: "•" }.freeze
        SEVERITY_COLOR = { error: :red, warning: :yellow, info: :blue }.freeze

        def initialize(io: $stdout, color: nil)
          @io = io
          @color = color.nil? ? io.tty? : color
        end

        def render(result)
          render_header(result)

          groups = result.by_destination
          if groups.values.all?(&:empty?)
            @io.puts c(:green, "  ✓ No issues found.")
            return
          end

          groups.each do |destination, findings|
            render_group(destination, findings)
          end

          render_summary(result)
        end

        private

        def render_header(result)
          version = Kamal::Lint::VERSION
          kamal = result.context&.kamal_version || "?"
          targets = result.destinations
          target_summary = describe_targets(targets)

          @io.puts "#{c(:bold, "kamal-lint")} #{c(:dim, version)} · kamal #{c(:cyan, kamal)} detected"
          @io.puts "  configs:    #{c(:cyan, target_summary)}"
          @io.puts
        end

        def describe_targets(targets)
          if targets == [ nil ]
            "config/deploy.yml"
          elsif targets.size == 1
            "config/deploy.#{targets.first}.yml"
          else
            names = targets.compact
            base = targets.include?(nil) ? "config/deploy.yml + " : ""
            "#{base}#{names.size} destination#{"s" if names.size != 1} (#{names.join(", ")})"
          end
        end

        def render_group(destination, findings)
          label = destination.nil? ? "base" : destination
          file = destination.nil? ? "config/deploy.yml" : "config/deploy.#{destination}.yml"
          @io.puts c(:bold, "[#{label}]") + c(:dim, " #{file}")

          if findings.empty?
            @io.puts "  #{c(:green, "✓")} No issues found."
            @io.puts
            return
          end

          findings
            .sort_by { |f| [ SEVERITIES.index(f.severity), f.line || 0 ] }
            .each { |finding| render_finding(finding) }
        end

        def render_finding(finding)
          loc = "#{finding.file}:#{finding.line || "?"}"
          glyph = SEVERITY_GLYPH[finding.severity] || "?"
          color = SEVERITY_COLOR[finding.severity] || :gray
          sev = finding.severity.to_s.ljust(7)

          @io.puts "  #{c(color, glyph)} #{c(:bold, sev)} #{c(:gray, loc)}"
          @io.puts "      #{finding.message}"
          @io.puts "      #{c(:dim, "[#{finding.check_id}]")}"
          @io.puts
        end

        def render_summary(result)
          errors = result.errors.size
          warnings = result.warnings.size
          infos = result.infos.size

          parts = []
          parts << "#{c(:red, errors.to_s)} error#{plural(errors)}" if errors > 0
          parts << "#{c(:yellow, warnings.to_s)} warning#{plural(warnings)}" if warnings > 0
          parts << "#{c(:blue, infos.to_s)} info" if infos > 0

          target_count = result.destinations.size
          tail = " across #{target_count} config#{plural(target_count)}" if target_count > 1
          @io.puts c(:bold, "Summary: ") + parts.join(", ") + tail.to_s
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
