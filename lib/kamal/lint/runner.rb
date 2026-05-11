# frozen_string_literal: true

module Kamal
  module Lint
    Result = Struct.new(:findings, :context, keyword_init: true) do
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
        registry: Lint.registry, include_kamal_errors: false)
        @config_file = config_file
        @destination = destination
        @kamal_version_override = kamal_version
        @registry = registry
        @include_kamal_errors = include_kamal_errors
      end

      def call
        context = Loader.load(
          config_file: @config_file,
          destination: @destination,
          kamal_version: @kamal_version_override,
          include_kamal_errors: @include_kamal_errors
        )
        findings = @registry.applicable_to(context.kamal_version).flat_map do |check_class|
          Array(check_class.new(context).call)
        end
        Result.new(findings: findings, context: context)
      end
    end
  end
end
