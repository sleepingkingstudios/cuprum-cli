# frozen_string_literal: true

require 'cuprum/cli/files/template'
require 'cuprum/cli/files/templates'

module Cuprum::Cli::Files::Templates # rubocop:disable Style/Documentation
  # Data class representing a template defined on a file.
  FileTemplate =
    Cuprum::Cli::Files::Template.define(:file_path, :file_system) do
      # @overload initialize(file_path:, engine: nil)
      #   @param engine [Symbol] the engine used to generate the template
      #     contents.
      #   @param file_path [String] the path to the template file.
      def initialize(file_path:, engine: nil, file_system: nil, **)
        file_system ||= Cuprum::Cli::Dependencies.provider.get('file_system')

        super(engine:, file_path:, file_system:, **)
      end

      # (see Cuprum::Cli::Files::Template#call)
      def call
        success(file_system.read_file(file_path))
      rescue Cuprum::Cli::Dependencies::FileSystem::FileNotFoundError
        error = Cuprum::Cli::Errors::Files::MissingTemplate.new(
          message:       'unable to generate file',
          template_path: file_path
        )
        failure(error)
      end
    end

  FileTemplate.class_eval do
    class << self
      # Converts a raw file path to a template.
      #
      # @param file_path [String] the input file path.
      #
      # @return [FileTemplate] the generated template.
      def build(file_path)
        engine =
          case File.extname(file_path)
          when '.erb' then Cuprum::Cli::Files::Engines::ERB
          end

        new(engine:, file_path:)
      end
    end
  end
end
