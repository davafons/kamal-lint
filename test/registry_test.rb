# frozen_string_literal: true

require "test_helper"

class RegistryTest < ActiveSupport::TestCase
  def setup
    @registry = Kamal::Lint::Registry.new
    @check_a = Class.new(Kamal::Lint::Check) do
      id "a"
      severity :error
      since "2.0.0"
      until_version "3.0.0"
    end
    @check_b = Class.new(Kamal::Lint::Check) do
      id "b"
      severity :warning
      since "2.5.0"
    end
  end

  def test_register_each_check_once
    @registry.register(@check_a)
    @registry.register(@check_a)
    assert_equal [ @check_a ], @registry.all
  end

  def test_filter_by_version
    @registry.register(@check_a)
    @registry.register(@check_b)

    assert_equal [ @check_a ], @registry.applicable_to("2.4.0")
    assert_equal [ @check_a, @check_b ], @registry.applicable_to("2.5.0")
    assert_equal [ @check_b ], @registry.applicable_to("3.0.0")
  end

  def test_nil_version_returns_all
    @registry.register(@check_a)
    @registry.register(@check_b)
    assert_equal [ @check_a, @check_b ], @registry.applicable_to(nil)
  end

  def test_default_registry_has_builtins
    ids = Kamal::Lint.registry.all.map(&:id)
    assert_includes ids, "secret-not-declared"
    assert_includes ids, "traefik-legacy-keys"
    assert_includes ids, "missing-service-name"
    assert ids.size >= 16, "expected ≥16 built-in checks, got #{ids.size}"
  end
end
