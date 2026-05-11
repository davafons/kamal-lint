# frozen_string_literal: true

module Kamal
  module Lint
    module Checks
      class MissingServiceName < Check
        id "missing-service-name"
        severity :error
        since "2.0.0"
        title "`service:` is required and missing"

        def call
          service = parsed["service"]
          return [] if service.is_a?(String) && !service.strip.empty?

          [ finding(
            message: "`service:` is required; without it Kamal can't name the deployed container",
            line: 1
          ) ]
        end
      end

      Lint.registry.register(MissingServiceName)
    end
  end
end
