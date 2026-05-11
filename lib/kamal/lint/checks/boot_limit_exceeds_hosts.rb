# frozen_string_literal: true

require_relative "../servers_helper"

module Kamal
  module Lint
    module Checks
      class BootLimitExceedsHosts < Check
        id "boot-limit-exceeds-hosts"
        severity :warning
        since "2.0.0"
        title "`boot.limit` exceeds the number of hosts (no rolling effect)"

        def call
          boot = parsed["boot"]
          return [] unless boot.is_a?(Hash)

          limit = boot["limit"]
          return [] unless limit.is_a?(Integer) && limit > 0

          host_count = ServersHelper.all_hosts(parsed["servers"]).uniq.size
          return [] if host_count == 0 || limit <= host_count

          [ finding(
            message: "boot.limit is #{limit} but only #{host_count} host(s) are configured; the limit has no effect",
            line: context.line_for([ "boot", "limit" ])
          ) ]
        end
      end

      Lint.registry.register(BootLimitExceedsHosts)
    end
  end
end
