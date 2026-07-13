# frozen_string_literal: true

require 'cuprum/cli/files'

module Cuprum::Cli::Files
  # Command for generating templated files.
  class Generator
    extend  Cuprum::Cli::Options::ClassMethods
    include Cuprum::Cli::Options::Quiet
    include Cuprum::Cli::Options::Verbose

    class << self
      # Marks the generator as abstract.
      def abstract = @abstract = true

      # @return [true, false] true if the generator is abstract and should not
      #   be assigned matchers or outputs; otherwise false.
      def abstract? = @abstract.nil? ? false : @abstract
    end

    abstract

    option :dry_run, type: :boolean

    # @overload initialize(file_path, **options)
    #   @param file_path [String] the input file path provided by the user.
    #   @param options [Hash] additional options for the generator.
    #
    #   @option options dry_run [true, false] if true, simulates file generation
    #     but does not perform the actual file system operations. Defaults to
    #     false.
    #   @option options quiet [true, false] if true, does not print generated
    #     file names status to STDOUT. Defaults to false.
    #   @option options verbose [true, false] if true, prints the contents of
    #     generated files to STDOUT. Defaults to false.
    def initialize(file_path, **)
      @file_path = file_path
      @options   = self.class.resolve_options(**)
    end

    # @return [String] the input file path provided by the user.
    attr_reader :file_path

    # @return [Hash] additional options for the generator.
    attr_reader :options

    # @return [Hash] parameters extracted from the input file name.
    def file_parameters
      @file_parameters ||= extract_file_parameters(file_path)
    end

    private

    def extract_file_parameters(file_path) # rubocop:disable Metrics/MethodLength
      base_name = File.basename(file_path)
      segments  = file_path.split(File::SEPARATOR)

      {
        base_name:,
        dir_name:      File.dirname(file_path),
        ext_name:      File.extname(file_path),
        file_path:,
        relative_path: segments[1...-1].join(File::SEPARATOR),
        root_path:     segments[0...-1].first || '',
        short_name:    base_name.split('.').first
      }
    end

    def resolve_output_path(output_path)
      params = file_parameters.merge(options)

      format(output_path, params).gsub(%r{//+}, '/')
    end
  end
end
