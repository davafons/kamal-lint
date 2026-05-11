# frozen_string_literal: true

module Kamal
  module Lint
    Finding = Struct.new(
      :check_id,
      :severity,
      :message,
      :file,
      :line,
      :column,
      :autofix,
      keyword_init: true
    ) do
      def autofixable?
        !autofix.nil?
      end

      def to_h
        {
          check: check_id,
          severity: severity.to_s,
          message: message,
          file: file,
          line: line,
          column: column,
          autofixable: autofixable?
        }
      end
    end
  end
end
