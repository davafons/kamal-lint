# frozen_string_literal: true

require "test_helper"

class FindingTest < ActiveSupport::TestCase
  def test_autofixable_when_callable_set
    f = Kamal::Lint::Finding.new(
      check_id: "x", severity: :warning, message: "m",
      file: "f", line: 1, column: 1,
      autofix: ->(_ctx) { true }
    )
    assert_predicate f, :autofixable?
  end

  def test_not_autofixable_without_callable
    f = Kamal::Lint::Finding.new(
      check_id: "x", severity: :error, message: "m",
      file: "f", line: 1, column: 1, autofix: nil
    )
    refute_predicate f, :autofixable?
  end

  def test_to_h
    f = Kamal::Lint::Finding.new(
      check_id: "x", severity: :info, message: "m",
      file: "f", line: 2, column: 3, autofix: nil
    )
    expected = {
      check: "x", severity: "info", message: "m",
      file: "f", line: 2, column: 3, autofixable: false
    }
    assert_equal expected, f.to_h
  end
end
