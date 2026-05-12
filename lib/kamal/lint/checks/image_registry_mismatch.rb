# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class ImageRegistryMismatch < Check
        id "image-registry-mismatch"
        severity :error
        since "2.0.0"
        title "`image:` registry prefix doesn't match `builder.registry.server`"

        # Docker Hub accepts unprefixed images (`myorg/myapp` resolves to
        # `docker.io/myorg/myapp`), so we don't flag a missing prefix when the
        # configured registry is Docker Hub under any of its canonical names.
        DOCKER_HUB_HOSTS = %w[docker.io index.docker.io registry.hub.docker.com].freeze

        # A leading path segment is treated as a registry host when it contains
        # a `.` or `:` (e.g. `ghcr.io`, `localhost:5000`) — Kamal sees that as
        # a host and won't add the configured server in front of it.
        def call
          image = parsed["image"]
          registry = parsed["registry"] || parsed.dig("builder", "registry") || {}
          server = registry["server"] if registry.is_a?(Hash)
          return [] unless image.is_a?(String) && server.is_a?(String) && !server.empty?

          normalized_server = server.sub(%r{/+\z}, "")
          return [] if DOCKER_HUB_HOSTS.include?(normalized_server)

          first_segment = image.split("/", 2).first.to_s
          looks_like_host = first_segment.include?(".") || first_segment.include?(":")

          # Unprefixed `org/repo` is the canonical Kamal style — the registry
          # server is prepended automatically. Only flag when the image already
          # carries a registry host that disagrees with `registry.server`.
          return [] unless looks_like_host
          return [] if image.start_with?("#{normalized_server}/")

          [ finding(
            message: "image `#{image}` is prefixed with a registry host that disagrees with `registry.server: #{server}`; Kamal will push to the wrong registry",
            line: context.line_for([ "image" ])
          ) ]
        end
      end

      Lint.registry.register(ImageRegistryMismatch)
    end
  end
end
