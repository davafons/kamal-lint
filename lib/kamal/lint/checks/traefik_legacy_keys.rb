# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class TraefikLegacyKeys < Check
        id "traefik-legacy-keys"
        severity :warning
        since "2.0.0"
        title "Kamal 1.x `traefik:` keys present (use `proxy:` in Kamal 2+)"

        def call
          return [] unless parsed.key?("traefik")

          [ finding(
            message: "`traefik:` block is Kamal 1.x legacy and is ignored in Kamal 2+; replace it with a `proxy:` block",
            line: context.line_for([ "traefik" ])
          ) ]
        end
      end

      Lint.registry.register(TraefikLegacyKeys)
    end
  end
end
