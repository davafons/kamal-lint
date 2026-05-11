# frozen_string_literal: true

require "psych"
require "pathname"
require "yaml"

module Kamal
  module Lint
    # Holds all the data a check needs to inspect a single Kamal config.
    Context = Struct.new(
      :config_file,
      :destination,
      :working_dir,
      :parsed,
      :base_parsed,
      :override_parsed,
      :line_index,
      :secrets,
      :secrets_path,
      :gitignore_path,
      :kamal_version,
      :kamal_loaded,
      :kamal_load_error,
      keyword_init: true
    ) do
      def file_for_finding
        return config_file unless destination

        override_path = override_file
        File.exist?(override_path) ? override_path : config_file
      end

      def override_file
        File.join(File.dirname(config_file), "deploy.#{destination}.yml")
      end

      def line_for(path)
        line_index[Array(path).join(".")]
      end
    end

    module Loader
      module_function

      def load(config_file:, destination: nil, kamal_version: nil)
        raise ConfigNotFoundError, "Config file not found: #{config_file}" unless File.exist?(config_file)

        working_dir = derive_working_dir(config_file)
        base_text, base_parsed = read_yaml(config_file)
        override_parsed = read_override(config_file, destination)
        kamal_loaded, kamal_load_error = try_kamal_load(config_file, destination, working_dir)

        Context.new(
          config_file: config_file,
          destination: destination,
          working_dir: working_dir,
          parsed: override_parsed ? deep_merge(base_parsed, override_parsed) : base_parsed,
          base_parsed: base_parsed,
          override_parsed: override_parsed,
          line_index: build_line_index(base_text),
          secrets: SecretsFile.read_keys(File.join(working_dir, ".kamal", "secrets")),
          secrets_path: File.join(working_dir, ".kamal", "secrets"),
          gitignore_path: File.join(working_dir, ".gitignore"),
          kamal_version: kamal_version || KamalVersion.detect,
          kamal_loaded: kamal_loaded,
          kamal_load_error: kamal_load_error
        )
      end

      def derive_working_dir(config_file)
        Pathname.new(config_file).realpath.dirname.dirname.to_s
      end

      def read_yaml(path)
        text = File.read(path)
        [ text, safe_parse_yaml(text) ]
      end

      def read_override(config_file, destination)
        return nil unless destination

        override_path = File.join(File.dirname(config_file), "deploy.#{destination}.yml")
        return nil unless File.exist?(override_path)

        safe_parse_yaml(File.read(override_path))
      end

      # Invoke Kamal's own loader so we can capture (and selectively surface)
      # the errors it would raise at deploy time. The returned config object is
      # discarded — checks operate on the parsed Hash so they retain source
      # line numbers.
      def try_kamal_load(config_file, destination, working_dir)
        require "kamal"
        Dir.chdir(working_dir) do
          Kamal::Configuration.create_from(
            config_file: Pathname.new(config_file),
            destination: destination,
            version: "kamal-lint"
          )
        end
        [ true, nil ]
      rescue => e
        [ false, e ]
      end

      def safe_parse_yaml(text)
        result = YAML.safe_load(text, aliases: true, permitted_classes: [ Symbol ])
        result.is_a?(Hash) ? result : {}
      rescue Psych::SyntaxError
        {}
      end

      def deep_merge(base, override)
        return override unless base.is_a?(Hash) && override.is_a?(Hash)

        result = base.dup
        override.each do |k, v|
          result[k] = if result[k].is_a?(Hash) && v.is_a?(Hash)
            deep_merge(result[k], v)
          else
            v
          end
        end
        result
      end

      # Build a mapping from dot-path ("env.secret") to source line numbers
      # by walking the Psych AST.
      def build_line_index(text)
        index = {}
        Psych.parse_stream(text).children.each do |doc|
          walk_node(doc.root, [], index)
        end
        index
      rescue Psych::SyntaxError
        index || {}
      end

      def walk_node(node, path, index)
        case node
        when Psych::Nodes::Mapping
          node.children.each_slice(2) do |key_node, value_node|
            next unless key_node && value_node

            new_path = path + [ key_node.value ]
            index[new_path.join(".")] ||= key_node.start_line + 1
            walk_node(value_node, new_path, index)
          end
        when Psych::Nodes::Sequence
          node.children.each_with_index do |child, idx|
            new_path = path + [ idx.to_s ]
            index[new_path.join(".")] ||= child.start_line + 1
            walk_node(child, new_path, index)
          end
        end
      end
    end
  end
end
