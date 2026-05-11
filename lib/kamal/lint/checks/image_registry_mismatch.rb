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

        def call
          image = parsed["image"]
          registry = parsed["registry"] || parsed.dig("builder", "registry") || {}
          server = registry["server"] if registry.is_a?(Hash)
          return [] unless image.is_a?(String) && server.is_a?(String) && !server.empty?

          normalized_server = server.sub(%r{/+\z}, "")
          return [] if DOCKER_HUB_HOSTS.include?(normalized_server)

          prefix = "#{normalized_server}/"
          return [] if image.start_with?(prefix)

          [ finding(
            message: "image `#{image}` does not include the configured registry `#{server}`; Kamal will push to the wrong registry",
            line: context.line_for([ "image" ])
          ) ]
        end
      end

      Lint.registry.register(ImageRegistryMismatch)
    end
  end
end
