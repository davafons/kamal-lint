# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      # Accessories must declare placement via at least one of:
      #   - host: <single host>
      #   - hosts: [<host>, ...]
      #   - roles: [<role>, ...]
      # An accessory with none of these has no defined target and Kamal won't
      # deploy it.
      class AccessoryPlacementMissing < Check
        id "accessory-placement-missing"
        severity :error
        since "2.0.0"
        title "Accessory has no `host`, `hosts`, or `roles` declared"

        def call
          accessories = parsed["accessories"]
          return [] unless accessories.is_a?(Hash)

          findings = []
          accessories.each do |name, accessory|
            next unless accessory.is_a?(Hash)

            has_placement = %w[host hosts roles].any? do |k|
              value = accessory[k]
              case value
              when String then !value.empty?
              when Array then value.any?
              else !value.nil?
              end
            end

            next if has_placement

            findings << finding(
              message: "accessory `#{name}` has no `host`, `hosts`, or `roles` declared; it will not be deployed anywhere",
              line: context.line_for([ "accessories", name ])
            )
          end
          findings
        end
      end

      Lint.registry.register(AccessoryPlacementMissing)
    end
  end
end
