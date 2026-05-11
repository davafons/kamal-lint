# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class MissingProxyHealthcheck < Check
        id "missing-proxy-healthcheck"
        severity :warning
        since "2.0.0"
        title "`proxy:` block has no healthcheck — zero-downtime deploys may fail"

        def call
          proxy = parsed["proxy"]
          return [] unless proxy.is_a?(Hash)
          return [] if proxy.key?("healthcheck")

          [ finding(
            message: "proxy block has no `healthcheck:` configured; Kamal-proxy can't verify a new release before cutover",
            line: context.line_for([ "proxy" ])
          ) ]
        end
      end

      Lint.registry.register(MissingProxyHealthcheck)
    end
  end
end
