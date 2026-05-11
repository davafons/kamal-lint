# frozen_string_literal: true

require "thor"

module Kamal
  module Lint
    class CLI < Thor
      def self.exit_on_failure?
        true
      end

      class_option :config_file, aliases: "-c", type: :string,
        default: "config/deploy.yml",
        desc: "Path to the Kamal deploy.yml"
      class_option :destination, aliases: "-d", type: :string,
        desc: "Destination override (e.g. production → config/deploy.production.yml)"
      class_option :format, aliases: "-f", type: :string, default: "human",
        enum: %w[human json github],
        desc: "Output format"
      class_option :fail_on, type: :string, default: "warning",
        enum: %w[error warning info],
        desc: "Minimum severity that causes a non-zero exit code"
      class_option :fix, type: :boolean, default: false,
        desc: "Apply safe autofixes in-place"
      class_option :"kamal-version", type: :string,
        desc: "Override detected Kamal version"
      class_option :"include-kamal-errors", type: :boolean, default: false,
        desc: "Also surface errors from Kamal's own loader (off by default; use `kamal config` for that)"
      class_option :no_color, type: :boolean, default: false,
        desc: "Disable colored output"

      desc "lint", "Lint the Kamal deploy.yml (default command)"
      def lint
        runner = Runner.new(
          config_file: options[:config_file],
          destination: options[:destination],
          kamal_version: options[:"kamal-version"],
          fix: options[:fix],
          include_kamal_errors: options[:"include-kamal-errors"]
        )
        result = runner.call
        formatter = build_formatter(options[:format], options[:no_color])
        formatter.render(result)
        formatter.render_fix_summary(result) if options[:fix]
        exit(result.exit_code(fail_on: options[:fail_on].to_sym))
      rescue ConfigNotFoundError => e
        warn "kamal-lint: #{e.message}"
        exit(2)
      end

      default_task :lint

      desc "list-checks", "List all registered checks"
      def list_checks
        registry = Lint.registry
        format = options[:format]

        if format == "json"
          require "json"
          payload = registry.all.map do |check|
            {
              id: check.id,
              severity: check.severity.to_s,
              title: check.title,
              since: check.since,
              until_version: check.until_version,
              autofixable: check.autofixable
            }
          end
          puts JSON.pretty_generate(payload)
        else
          puts "#{"ID".ljust(38)} #{"SEVERITY".ljust(9)} #{"SINCE".ljust(8)} TITLE"
          puts "-" * 110
          registry.all.each do |check|
            line = [
              check.id.to_s.ljust(38),
              check.severity.to_s.ljust(9),
              (check.since || "—").to_s.ljust(8),
              check.title.to_s
            ].join(" ")
            line += " (autofixable)" if check.autofixable
            puts line
          end
          puts
          puts "Total: #{registry.all.size} checks"
        end
      end

      desc "version", "Show version"
      def version
        puts "kamal-lint #{Kamal::Lint::VERSION}"
      end

      map "--version" => :version
      map "-v" => :version

      no_commands do
        def build_formatter(name, no_color)
          klass = FORMATTERS.fetch(name) { raise ArgumentError, "unknown formatter: #{name}" }
          if klass == Formatters::Human
            klass.new(color: !no_color && $stdout.tty?)
          else
            klass.new
          end
        end
      end
    end
  end
end
