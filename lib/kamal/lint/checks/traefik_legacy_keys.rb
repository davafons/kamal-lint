# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class TraefikLegacyKeys < Check
        id "traefik-legacy-keys"
        severity :warning
        since "2.0.0"
        autofixable true
        title "Kamal 1.x `traefik:` keys present (use `proxy:` in Kamal 2+)"

        def call
          return [] unless parsed.key?("traefik")

          [ finding(
            message: "`traefik:` block is Kamal 1.x legacy and is ignored in Kamal 2+; use `proxy:` instead",
            line: context.line_for([ "traefik" ]),
            autofix: method(:apply_fix)
          ) ]
        end

        def apply_fix(ctx)
          file = ctx.file_for_finding
          text = File.read(file)
          parsed = YAML.safe_load(text, aliases: true) || {}
          return false unless parsed.is_a?(Hash) && parsed.key?("traefik")

          traefik = parsed.delete("traefik") || {}
          proxy = parsed["proxy"] || {}

          # Conservative translation:
          # - traefik.host           → proxy.host
          # - traefik.ssl_redirect   → proxy.ssl: true (Kamal 2 handles SSL via proxy.ssl)
          # - traefik.args.entryPoints.address: ":<port>" → proxy.app_port: <port>
          if (host = traefik["host"]) && !proxy["host"]
            proxy["host"] = host
          end
          if traefik["ssl_redirect"] == true || traefik.dig("args", "entrypoints.websecure.address")
            proxy["ssl"] = true unless proxy.key?("ssl")
          end
          if (addr = traefik.dig("args", "entrypoints.web.address")) && addr.is_a?(String)
            port = addr.scan(/\d+/).first
            proxy["app_port"] = port.to_i if port && !proxy.key?("app_port")
          end

          parsed["proxy"] = proxy unless proxy.empty?
          File.write(file, YAML.dump(parsed))
          true
        rescue => _e
          false
        end
      end

      Lint.registry.register(TraefikLegacyKeys)
    end
  end
end
