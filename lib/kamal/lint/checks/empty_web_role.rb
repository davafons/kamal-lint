# frozen_string_literal: true

require_relative "../servers_helper"

module Kamal
  module Lint
    module Checks
      class EmptyWebRole < Check
        id "empty-web-role"
        severity :error
        since "2.0.0"
        title "No web role / no hosts to deploy to"

        def call
          servers = parsed["servers"]

          all_hosts = ServersHelper.all_hosts(servers)
          if servers.nil? || (servers.is_a?(Enumerable) && servers.empty?)
            return [ finding(
              message: "`servers:` is missing or empty; nothing will be deployed",
              line: context.line_for([ "servers" ]) || 1
            ) ]
          end

          return [] unless all_hosts.empty?

          [ finding(
            message: "no hosts declared under any role in `servers:`; nothing will be deployed",
            line: context.line_for([ "servers" ]) || 1
          ) ]
        end
      end

      Lint.registry.register(EmptyWebRole)
    end
  end
end
