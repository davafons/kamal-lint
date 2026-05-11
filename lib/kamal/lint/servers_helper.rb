# frozen_string_literal: true

module Kamal
  module Lint
    # Helpers for walking `servers:` in its various shapes:
    #
    #   servers: [host1, host2]                            → implicit "web" role
    #   servers: { web: [...], workers: [...] }            → role => hosts
    #   servers: { web: { hosts: [...], cmd: ..., ... } }  → role => expanded
    module ServersHelper
      module_function

      def role_names(servers)
        case servers
        when Array
          [ "web" ]
        when Hash
          servers.keys.map(&:to_s)
        else
          []
        end
      end

      def hosts_for_role(servers, role)
        case servers
        when Array
          role == "web" ? servers.dup : []
        when Hash
          entry = servers[role] || servers[role.to_sym]
          extract_hosts(entry)
        else
          []
        end
      end

      def all_hosts(servers)
        case servers
        when Array
          servers.dup
        when Hash
          servers.values.flat_map { |v| extract_hosts(v) }
        else
          []
        end
      end

      def extract_hosts(entry)
        case entry
        when Array
          entry
        when Hash
          hosts = entry["hosts"] || entry[:hosts] || []
          hosts.is_a?(Array) ? hosts : [ hosts ].compact
        else
          []
        end
      end
    end
  end
end
