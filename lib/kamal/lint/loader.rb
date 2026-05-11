# frozen_string_literal: true

require "psych"
require "pathname"
require "yaml"

module Kamal
  module Lint
    # Holds all the data a check needs to inspect a single Kamal config:
    # the parsed YAML, the source lines, helper to look up source lines for a
    # given path (for finding line numbers), the destination override, the
    # secrets file contents, and a flag indicating whether Kamal's own loader
    # rejected the config (in which case some checks are skipped to avoid
    # cascading false positives).
    Context = Struct.new(
      :config_file,
      :destination,
      :working_dir,
      :parsed,
      :base_parsed,
      :override_parsed,
      :source_lines,
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

        working_dir = Pathname.new(config_file).realpath.dirname.dirname.to_s
        # If config_file is at config/deploy.yml inside a project, working_dir = project root.
        # If the user pointed somewhere else, fall back to its parent dir's parent.

        base_text = File.read(config_file)
        base_parsed = safe_parse_yaml(base_text)
        source_lines = base_text.lines

        override_parsed = nil
        if destination
          override_path = File.join(File.dirname(config_file), "deploy.#{destination}.yml")
          if File.exist?(override_path)
            override_parsed = safe_parse_yaml(File.read(override_path))
            source_lines = File.read(override_path).lines
          end
        end

        merged = override_parsed ? deep_merge(base_parsed, override_parsed) : base_parsed

        line_index = build_line_index(base_text)
        secrets_path = File.join(working_dir, ".kamal", "secrets")
        gitignore_path = File.join(working_dir, ".gitignore")
        secrets_keys = SecretsFile.read_keys(secrets_path)

        loaded = true
        load_error = nil
        begin
          # Run Kamal's own loader for parse-level validation. We don't use the
          # returned object — we keep working off the parsed Hash so we can
          # report line numbers — but we surface Kamal's own errors as findings.
          require "kamal"
          Dir.chdir(working_dir) do
            Kamal::Configuration.create_from(
              config_file: Pathname.new(config_file),
              destination: destination,
              version: "kamal-lint"
            )
          end
        rescue => e
          loaded = false
          load_error = e
        end

        Context.new(
          config_file: config_file,
          destination: destination,
          working_dir: working_dir,
          parsed: merged || {},
          base_parsed: base_parsed || {},
          override_parsed: override_parsed,
          source_lines: source_lines,
          line_index: line_index,
          secrets: secrets_keys,
          secrets_path: secrets_path,
          gitignore_path: gitignore_path,
          kamal_version: kamal_version || KamalVersion.detect,
          kamal_loaded: loaded,
          kamal_load_error: load_error
        )
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

      # Build a mapping from dot-path ("env.secret") to source line numbers.
      # Walks the Psych AST.
      def build_line_index(text)
        index = {}
        stream = Psych.parse_stream(text)
        stream.children.each do |doc|
          walk_node(doc.root, [], index)
        end
        index
      rescue Psych::SyntaxError
        index
      end

      def walk_node(node, path, index)
        case node
        when Psych::Nodes::Mapping
          node.children.each_slice(2) do |key_node, value_node|
            next unless key_node && value_node

            key = key_node.value
            new_path = path + [ key ]
            index[new_path.join(".")] ||= key_node.start_line + 1
            walk_node(value_node, new_path, index)
          end
        when Psych::Nodes::Sequence
          node.children.each_with_index do |child, idx|
            new_path = path + [ idx.to_s ]
            # Index the position itself so checks can find sequence elements
            # by ordinal (e.g. "env.secret.0").
            index[new_path.join(".")] ||= child.start_line + 1
            walk_node(child, new_path, index)
          end
        when Psych::Nodes::Scalar
          # Scalars at non-root locations need no further indexing; their
          # parent already wrote the line for them.
        end
      end
    end
  end
end
