# frozen_string_literal: true

require 'cuprum/cli/errors/files'
require 'cuprum/cli/errors/files/template_error'

module Cuprum::Cli::Errors::Files
  # Error returned when unable to resolve a template for a templated file.
  class TemplateNotResolved < Cuprum::Cli::Errors::Files::TemplateError
    # Short string used to identify the type of error.
    TYPE = 'cuprum.cli.errors.files.template_not_resolved'

    # @param file_path [String] the file path for the templated file.
    # @param details [String] additional information about the error.
    # @param message [String] an optional message to display.
    # @param options [Hash] options used when attempting to resolve the
    #   template.
    def initialize(file_path:, details: nil, message: nil, options: {})
      @file_path = file_path
      @options   = options

      super(details:, file_path:, message: default_message(message), options:)
    end

    # @return [String] the file path for the templated file.
    attr_reader :file_path

    # @return [Hash] options used when attempting to resolve the template.
    attr_reader :options

    private

    def as_json_data
      hsh = super

      hsh['file_path'] = file_path
      hsh['options']   = options.transform_keys(&:to_s) unless options.empty?

      hsh
    end

    def default_message(message)
      str = "unable to resolve template for file #{file_path}"
      str = "#{str} with options" unless options.empty?

      options.each.with_index do |(key, value), index|
        str += "#{',' unless index.zero?} #{key}: #{value.inspect}"
      end

      return str unless message && !message.empty?

      "#{str} - #{message}"
    end
  end
end
