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
      :destination,
      keyword_init: true
    ) do
      def to_h
        {
          check: check_id,
          severity: severity.to_s,
          message: message,
          file: file,
          line: line,
          column: column,
          destination: destination
        }
      end
    end
  end
end
