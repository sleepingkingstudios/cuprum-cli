# frozen_string_literal: true

require 'cuprum/cli/files'

module Cuprum::Cli::Files
  # Namespace for template files and implementations.
  module Templates
    autoload :BasicTemplate,  'cuprum/cli/files/templates/basic_template'
    autoload :FileTemplate,   'cuprum/cli/files/templates/file_template'
    autoload :StringTemplate, 'cuprum/cli/files/templates/string_template'

    class << self
      # Converts a raw input string to a template object.
      #
      # - If the input is a Template, returns the input.
      # - If the input is a single-line String, generates and returns a
      #   FileTemplate with the input as the file path.
      # - If the input is a multi-line String, generates and returns a
      #   StringTemplate with the input as the raw template value.
      # - For all other values, raises an ArgumentError.
      #
      # @param maybe_template [Cuprum::Cli::Files::Template, String] the
      #   template or unprocessed template string.
      #
      # @return [Cuprum::Cli::Files::Template] the generated template.
      def resolve(maybe_template)
        if maybe_template.is_a?(Cuprum::Cli::Files::Template)
          return maybe_template
        end

        if maybe_template.is_a?(String)
          return build_template_from_string(maybe_template)
        end

        tools.assertions.validate_presence(maybe_template, as: 'template')

        raise ArgumentError, 'template must be a Template or file path'
      end

      private

      def build_template_from_string(maybe_template)
        tools.assertions.validate_presence(maybe_template, as: 'template')

        if file_path?(maybe_template)
          Cuprum::Cli::Files::Templates::FileTemplate.build(maybe_template)
        else
          Cuprum::Cli::Files::Templates::StringTemplate.build(maybe_template)
        end
      end

      def file_path?(value)
        !value.include?("\n")
      end

      def tools = SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
