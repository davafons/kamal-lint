# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class MissingServiceName < Check
        id "missing-service-name"
        severity :error
        since "2.0.0"
        autofixable true
        title "`service:` is required and missing"

        def call
          service = parsed["service"]
          return [] if service.is_a?(String) && !service.strip.empty?

          [ finding(
            message: "`service:` is required; without it Kamal can't name the deployed container",
            line: 1,
            autofix: method(:apply_fix)
          ) ]
        end

        def apply_fix(ctx)
          file = ctx.file_for_finding
          text = File.read(file)
          parsed = YAML.safe_load(text, aliases: true) || {}
          return false if parsed["service"].is_a?(String) && !parsed["service"].empty?

          name = File.basename(ctx.working_dir).gsub(/[^A-Za-z0-9_-]/, "-")
          return false if name.empty?

          # Parse-and-dump so the fix composes safely with other autofixes
          # that may also rewrite the file. The trade-off is that comments
          # in the original YAML are lost — documented in the README.
          File.write(file, YAML.dump({ "service" => name }.merge(parsed)))
          true
        rescue
          false
        end
      end

      Lint.registry.register(MissingServiceName)
    end
  end
end
