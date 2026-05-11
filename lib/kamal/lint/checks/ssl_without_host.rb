# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class SslWithoutHost < Check
        id "ssl-without-host"
        severity :error
        since "2.0.0"
        title "SSL enabled without a host configured"

        def call
          proxy = parsed["proxy"]
          return [] unless proxy.is_a?(Hash)

          ssl_enabled = proxy["ssl"] == true
          return [] unless ssl_enabled

          host = proxy["host"]
          hosts = proxy["hosts"]

          host_set = (host.is_a?(String) && !host.empty?) ||
                     (hosts.is_a?(Array) && hosts.any? { |h| h.is_a?(String) && !h.empty? })

          return [] if host_set

          [ finding(
            message: "proxy.ssl: true requires `host:` (or `hosts:`) to be set for automatic Let's Encrypt provisioning",
            line: context.line_for([ "proxy", "ssl" ]) || context.line_for([ "proxy" ])
          ) ]
        end
      end

      Lint.registry.register(SslWithoutHost)
    end
  end
end
