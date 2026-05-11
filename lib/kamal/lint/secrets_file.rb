# frozen_string_literal: true

module Kamal
  module Lint
    # Reads .kamal/secrets (shell-style KEY=value, with optional `export` prefix
    # and `#` comments). Returns the set of declared keys. We don't expand or
    # substitute — we only care whether a name is declared.
    module SecretsFile
      module_function

      def read_keys(path)
        return [] unless path && File.exist?(path)

        keys = []
        File.foreach(path) do |raw|
          line = raw.strip
          next if line.empty?
          next if line.start_with?("#")

          line = line.sub(/\Aexport\s+/, "")
          name, _eq, _value = line.partition("=")
          name = name.strip
          keys << name unless name.empty?
        end
        keys.uniq
      end
    end
  end
end
