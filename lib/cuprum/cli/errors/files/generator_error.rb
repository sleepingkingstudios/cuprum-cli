# frozen_string_literal: true

require 'cuprum/cli/errors/files'

module Cuprum::Cli::Errors::Files
  # Error returned when an error occurs when calling a generator.
  class GeneratorError < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'cuprum.cli.errors.files.generator_error'

    # @param message [String] message describing the nature of the error.
    # @param details [String] additional information about the error.
    # @param file_path [String] the file path passed to the generator.
    # @param options [Hash] additional options passed to the generator.
    def initialize(message:, details: nil, file_path: nil, options: {}, **)
      @details   = details
      @file_path = file_path
      @options   = options

      super
    end

    # @return [String] additional information about the error.
    attr_reader :details

    # @return [String] the file path passed to the generator.
    attr_reader :file_path

    # @return [Hash] additional options passed to the generator.
    attr_reader :options

    private

    def as_json_data
      options = self.options.empty? ? nil : self.options.transform_keys(&:to_s)

      super
        .merge(
          'details'   => details,
          'file_path' => file_path,
          'options'   => options
        )
        .compact
    end
  end
end
