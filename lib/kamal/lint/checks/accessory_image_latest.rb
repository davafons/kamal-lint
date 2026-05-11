# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class AccessoryImageLatest < Check
        id "accessory-image-latest"
        severity :warning
        since "2.0.0"
        title "Accessory image pinned to `:latest` (or unpinned)"

        def call
          accessories = parsed["accessories"]
          return [] unless accessories.is_a?(Hash)

          findings = []
          accessories.each do |name, accessory|
            next unless accessory.is_a?(Hash)

            image = accessory["image"]
            next unless image.is_a?(String) && !image.empty?

            tag = image.split(":", 2)[1]
            if tag.nil?
              findings << finding(
                message: "accessory `#{name}` image `#{image}` has no tag; defaults to `:latest` and updates unexpectedly",
                line: context.line_for([ "accessories", name, "image" ])
              )
            elsif tag == "latest"
              findings << finding(
                message: "accessory `#{name}` image pinned to `:latest`; pin to a specific version to keep deploys reproducible",
                line: context.line_for([ "accessories", name, "image" ])
              )
            end
          end
          findings
        end
      end

      Lint.registry.register(AccessoryImageLatest)
    end
  end
end
