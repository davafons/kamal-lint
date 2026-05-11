# frozen_string_literal: true

require_relative "../servers_helper"

module Kamal
  module Lint
    module Checks
      class RoleHostsEmpty < Check
        id "role-hosts-empty"
        severity :error
        since "2.0.0"
        title "A role under `servers:` has no hosts"

        def call
          servers = parsed["servers"]
          return [] unless servers.is_a?(Hash)

          findings = []
          servers.each do |role, entry|
            hosts = ServersHelper.extract_hosts(entry)
            next unless hosts.empty?

            findings << finding(
              message: "role `#{role}` under `servers` has no hosts; deploys to this role will silently no-op",
              line: context.line_for([ "servers", role.to_s ])
            )
          end
          findings
        end
      end

      Lint.registry.register(RoleHostsEmpty)
    end
  end
end
