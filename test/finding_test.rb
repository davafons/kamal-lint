# frozen_string_literal: true

require "test_helper"

class FindingTest < ActiveSupport::TestCase
  def test_to_h
    f = Kamal::Lint::Finding.new(
      check_id: "x", severity: :info, message: "m",
      file: "f", line: 2, column: 3
    )
    expected = {
      check: "x", severity: "info", message: "m",
      file: "f", line: 2, column: 3, destination: nil
    }
    assert_equal expected, f.to_h
  end
end
