# frozen_string_literal: true

require "yaml"
require "pathname"

module Kamal
  module Lint
    module Checks
      # Flags keys at the top level and under `proxy:` that aren't part
      # of Kamal's configuration schema.
      #
      # Drives off Kamal's own `lib/kamal/configuration/docs/*.yml`
      # example files — the same source kamal's runtime validator uses
      # for `check_unknown_keys!`. That makes the lint stay in sync
      # with whichever kamal version is installed.
      #
      # Also surfaces a targeted hint when an unknown key under
      # `proxy:` is actually a valid top-level Kamal key (the classic
      # `deploy_timeout` / `drain_timeout` misplacement after the 2.10
      # → 2.11 schema move).
      class UnknownKeys < Check
        id "unknown-keys"
        severity :error
        since "2.0.0"
        title "Unknown key in Kamal config"

        def call
          findings = []
          walk_keys(parsed, top_level_schema, [], findings)
          if parsed.is_a?(Hash) && parsed["proxy"].is_a?(Hash)
            walk_keys(parsed["proxy"], proxy_schema, [ "proxy" ], findings)
          end
          findings
        end

        private

        def walk_keys(config, schema, path, findings)
          return unless config.is_a?(Hash) && schema.is_a?(Hash)

          allowed = schema.keys.map(&:to_s)
          config.each_key do |key|
            key_str = key.to_s
            next if key_str.start_with?("x-")  # kamal extension prefix
            next if allowed.include?(key_str)

            findings << finding(
              message: message_for(key_str, path),
              line: context.line_for(path + [ key ])
            )
          end
        end

        def message_for(key_str, path)
          full = (path + [ key_str ]).join(".")
          # Inside a sub-block? Check whether the key is actually valid
          # at the top level — common foot-gun is misplacement.
          if !path.empty? && top_level_schema.keys.map(&:to_s).include?(key_str)
            "`#{full}` is a top-level Kamal key — move it out of the `#{path.join('.')}:` block"
          else
            "unknown key `#{full}` — Kamal will reject this at deploy time"
          end
        end

        def top_level_schema
          @top_level_schema ||= load_doc("configuration.yml") || {}
        end

        def proxy_schema
          @proxy_schema ||= begin
            doc = load_doc("proxy.yml")
            doc.is_a?(Hash) && doc["proxy"].is_a?(Hash) ? doc["proxy"] : {}
          end
        end

        # Load a kamal docs example yaml from the installed kamal gem.
        # Returns nil on any load failure so the check stays silent
        # rather than crashing the lint run. We `require "kamal"`
        # (not "kamal/configuration") because the inner configuration
        # file references `Kamal::Utils` which isn't autoloaded from
        # the sub-require.
        def load_doc(filename)
          require "kamal"
          spec = Gem.loaded_specs["kamal"] or return nil
          path = Pathname.new(spec.gem_dir).join("lib/kamal/configuration/docs", filename)
          return nil unless path.exist?
          YAML.load(File.read(path))
        rescue StandardError
          nil
        end
      end

      Lint.registry.register(UnknownKeys)
    end
  end
end
