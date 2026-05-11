# frozen_string_literal: true

module Kamal
  module Lint
    # Base class for all checks.
    #
    # Subclasses declare their identity and applicable Kamal version range with
    # the DSL methods below and implement `#call(context)` returning an Array of
    # Findings (possibly empty).
    class Check
      class << self
        def id(value = nil)
          @id = value if value
          @id
        end

        def severity(value = nil)
          @severity = value if value
          @severity || :warning
        end

        def title(value = nil)
          @title = value if value
          @title
        end

        def since(value = nil)
          @since = value if value
          @since
        end

        def until_version(value = nil)
          @until_version = value if value
          @until_version
        end

        # Mark this check as autofix-capable in the registry listing.
        def autofixable(value = nil)
          @autofixable = value unless value.nil?
          @autofixable || false
        end

        def applies_to?(kamal_version)
          return true if kamal_version.nil?

          if @since && Gem::Version.new(kamal_version) < Gem::Version.new(@since)
            return false
          end
          if @until_version && Gem::Version.new(kamal_version) >= Gem::Version.new(@until_version)
            return false
          end

          true
        end
      end

      def initialize(context)
        @context = context
      end

      attr_reader :context

      def call
        raise NotImplementedError
      end

      private

      def finding(message:, line: nil, column: nil, autofix: nil)
        Finding.new(
          check_id: self.class.id,
          severity: self.class.severity,
          message: message,
          file: context.file_for_finding,
          line: line,
          column: column,
          autofix: autofix
        )
      end

      def parsed
        context.parsed
      end

      def secrets
        context.secrets
      end
    end
  end
end
