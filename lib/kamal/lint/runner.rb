# frozen_string_literal: true

module Kamal
  module Lint
    Result = Struct.new(:findings, :context, :destinations, keyword_init: true) do
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

      # Findings grouped by destination (nil for base), preserving the
      # discovery order: base first, then each destination alphabetically.
      def by_destination
        groups = { nil => [] }
        destinations.each { |d| groups[d] = [] }
        findings.each do |f|
          (groups[f.destination] ||= []) << f
        end
        groups
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
        targets = discover_targets
        all_findings = []
        last_context = nil

        targets.each do |destination|
          context = Loader.load(
            config_file: @config_file,
            destination: destination,
            kamal_version: @kamal_version_override,
            include_kamal_errors: @include_kamal_errors
          )
          last_context = context

          @registry.applicable_to(context.kamal_version).each do |check_class|
            Array(check_class.new(context).call).each do |finding|
              finding.destination = destination
              all_findings << finding
            end
          end
        end

        Result.new(findings: all_findings, context: last_context, destinations: targets)
      end

      private

      # When a destination is explicitly requested, lint only that one.
      # Otherwise discover every config/deploy.*.yml override and lint each.
      # If destinations exist, the bare base config is skipped — it isn't
      # meant to be deployed standalone, so checks like `empty-web-role` or
      # missing-secrets would always fire on the unmerged template.
      def discover_targets
        return [ @destination ] if @destination

        destinations = auto_discover_destinations
        destinations.empty? ? [ nil ] : destinations
      end

      def auto_discover_destinations
        dir = File.dirname(@config_file)
        base = File.basename(@config_file, ".yml")
        glob = File.join(dir, "#{base}.*.yml")

        Dir.glob(glob).map do |path|
          File.basename(path, ".yml").sub(/\A#{Regexp.escape(base)}\./, "")
        end.sort
      end
    end
  end
end
