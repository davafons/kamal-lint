# frozen_string_literal: true

require "open3"

module Kamal
  module Lint
    # Detect the installed Kamal version from (in priority order):
    #   1. explicit override
    #   2. Bundler.locked_gems
    #   3. Gem.loaded_specs / Gem::Specification
    #   4. shell out to `kamal version`
    module KamalVersion
      module_function

      def detect(override: nil)
        return normalize(override) if override

        from_bundler || from_loaded_specs || from_shell
      end

      def from_bundler
        return nil unless defined?(Bundler)

        locked = Bundler.locked_gems&.specs&.find { |s| s.name == "kamal" }
        locked&.version&.to_s
      rescue Bundler::GemfileNotFound
        nil
      rescue => _e
        nil
      end

      def from_loaded_specs
        spec = Gem.loaded_specs["kamal"] if defined?(Gem) && Gem.respond_to?(:loaded_specs)
        return spec.version.to_s if spec

        if defined?(Gem::Specification)
          found = Gem::Specification.find_all_by_name("kamal").max_by(&:version)
          return found&.version&.to_s
        end

        nil
      rescue => _e
        nil
      end

      def from_shell
        out, _err, status = Open3.capture3("kamal", "version")
        return nil unless status.success?

        out.strip.split.last
      rescue Errno::ENOENT
        nil
      end

      def normalize(value)
        return nil if value.nil? || value.to_s.empty?

        value.to_s.strip
      end
    end
  end
end
