# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class AccessoryRoleUndefined < Check
        id "accessory-role-undefined"
        severity :error
        since "2.0.0"
        title "Accessory `roles:` lists a role not defined under `servers`"

        def call
          findings = []
          accessories = parsed["accessories"]
          return findings unless accessories.is_a?(Hash)

          defined_roles = ServersHelper.role_names(parsed["servers"])

          accessories.each do |name, accessory|
            next unless accessory.is_a?(Hash)

            roles = accessory["roles"]
            next unless roles.is_a?(Array)

            roles.each_with_index do |role, idx|
              next unless role.is_a?(String)
              next if defined_roles.include?(role)

              findings << finding(
                message: "accessory `#{name}` references role `#{role}` which is not defined under `servers`",
                line: context.line_for([ "accessories", name, "roles", idx.to_s ])
              )
            end
          end

          findings
        end
      end

      Lint.registry.register(AccessoryRoleUndefined)
    end
  end
end
