# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class RegistryWithoutExplicitServer < Check
        id "registry-without-explicit-server"
        severity :warning
        since "2.0.0"
        title "`registry.server` not set; image will default to Docker Hub"

        def call
          registry = parsed["registry"] || parsed.dig("builder", "registry")
          return [] unless registry.is_a?(Hash)

          server = registry["server"]
          return [] if server.is_a?(String) && !server.empty?

          image = parsed["image"]
          # If image already has an explicit registry prefix (host with a "."),
          # this is intentional and we don't warn.
          if image.is_a?(String) && image.include?("/")
            first_segment = image.split("/", 2).first
            return [] if first_segment.include?(".") || first_segment.include?(":")
          end

          [ finding(
            message: "registry has no `server:` set; Kamal will push/pull from Docker Hub by default",
            line: context.line_for([ "registry" ]) || context.line_for([ "registry", "username" ])
          ) ]
        end
      end

      Lint.registry.register(RegistryWithoutExplicitServer)
    end
  end
end
