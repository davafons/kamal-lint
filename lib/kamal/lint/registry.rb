# frozen_string_literal: true

module Kamal
  module Lint
    class Registry
      def self.default
        @default ||= new
      end

      def initialize
        @checks = []
      end

      def register(check_class)
        @checks << check_class unless @checks.include?(check_class)
        check_class
      end

      def all
        @checks.dup
      end

      def applicable_to(kamal_version)
        @checks.select { |c| c.applies_to?(kamal_version) }
      end

      def find(id)
        @checks.find { |c| c.id == id }
      end
    end
  end
end
