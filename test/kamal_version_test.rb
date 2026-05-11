# frozen_string_literal: true

require "test_helper"

class KamalVersionTest < ActiveSupport::TestCase
  def test_override_takes_priority
    assert_equal "9.9.9", Kamal::Lint::KamalVersion.detect(override: "9.9.9")
  end

  def test_override_is_stripped
    assert_equal "9.9.9", Kamal::Lint::KamalVersion.detect(override: "  9.9.9  ")
  end

  def test_detect_falls_back_to_loaded_specs
    version = Kamal::Lint::KamalVersion.detect
    assert_kind_of String, version
    assert_match(/\A\d+\.\d+/, version)
  end

  def test_normalize_handles_empty_input
    assert_nil Kamal::Lint::KamalVersion.normalize(nil)
    assert_nil Kamal::Lint::KamalVersion.normalize("")
  end
end
