# frozen_string_literal: true

require "test_helper"

class SecretsFileTest < ActiveSupport::TestCase
  def test_reads_simple_key_value
    Tempfile.create("secrets") do |f|
      f.write("A=1\nB=2\n")
      f.flush
      assert_equal %w[A B], Kamal::Lint::SecretsFile.read_keys(f.path)
    end
  end

  def test_ignores_comments_and_blanks
    Tempfile.create("secrets") do |f|
      f.write("# a comment\n\nA=1\n# another\nB=2\n")
      f.flush
      assert_equal %w[A B], Kamal::Lint::SecretsFile.read_keys(f.path)
    end
  end

  def test_strips_export_prefix
    Tempfile.create("secrets") do |f|
      f.write("export A=1\nexport  B=2\n")
      f.flush
      assert_equal %w[A B], Kamal::Lint::SecretsFile.read_keys(f.path)
    end
  end

  def test_missing_file_returns_empty
    assert_equal [], Kamal::Lint::SecretsFile.read_keys("/nonexistent/asdf")
  end

  def test_nil_path_returns_empty
    assert_equal [], Kamal::Lint::SecretsFile.read_keys(nil)
  end
end
