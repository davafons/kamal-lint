# frozen_string_literal: true

module Kamal
  module Lint
    Result = Struct.new(:findings, :context, :fixed, keyword_init: true) do
      def errors
        findings.select { |f| f.severity == :error }
      end

      def warnings
        findings.select { |f| f.severity == :warning }
      end

      def infos
        findings.select { |f| f.severity == :info }
      end

      def empty?
        findings.empty?
      end

      def exit_code(fail_on: :error)
        threshold = SEVERITIES.index(fail_on.to_sym)
        worst = findings.map { |f| SEVERITIES.index(f.severity) }.compact.min
        return 0 if worst.nil?

        worst <= threshold ? 1 : 0
      end
    end

    class Runner
      def initialize(config_file:, destination: nil, kamal_version: nil,
        registry: Lint.registry, fix: false, include_kamal_errors: false)
        @config_file = config_file
        @destination = destination
        @kamal_version_override = kamal_version
        @registry = registry
        @fix = fix
        @include_kamal_errors = include_kamal_errors
      end

      def call
        context = load_context
        findings = collect_findings(context)

        fixed = @fix ? apply_autofixes(findings, context) : []

        if @fix && !fixed.empty?
          context = load_context
          findings = collect_findings(context)
        end

        Result.new(findings: findings, context: context, fixed: fixed)
      end

      private

      def load_context
        Loader.load(
          config_file: @config_file,
          destination: @destination,
          kamal_version: @kamal_version_override
        )
      end

      def collect_findings(context)
        findings = []

        if @include_kamal_errors && context.kamal_load_error
          findings << kamal_parse_error_finding(context)
        end

        @registry.applicable_to(context.kamal_version).each do |check_class|
          findings.concat(Array(check_class.new(context).call))
        end

        findings
      end

      def kamal_parse_error_finding(context)
        Finding.new(
          check_id: "kamal-parse-error",
          severity: :error,
          message: "kamal could not load this config: #{context.kamal_load_error.message}",
          file: context.file_for_finding,
          line: 1,
          column: 1,
          autofix: nil
        )
      end

      def apply_autofixes(findings, context)
        applied = []
        findings.select(&:autofixable?).each do |finding|
          ok = finding.autofix.call(context)
          applied << finding if ok
        end
        applied
      end
    end
  end
end
