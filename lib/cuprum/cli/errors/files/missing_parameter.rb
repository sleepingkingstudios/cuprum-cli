# frozen_string_literal: true

require 'cuprum/cli/errors/files'
require 'cuprum/cli/errors/files/template_error'

module Cuprum::Cli::Errors::Files
  # Error returned when a required parameter is missing when rendering content.
  class MissingParameter < Cuprum::Cli::Errors::Files::TemplateError
    # Short string used to identify the type of error.
    TYPE = 'cuprum.cli.errors.files.missing_parameter'

    # @param parameter_name [String, Symbol] the name of the missing parameter.
    # @param details [String] additional information about the error.
    # @param format [String] the content format.
    # @param message [String] an optional message to display.
    # @param template_name [String] the name of the rendered content, if any,
    def initialize(
      parameter_name:,
      details: nil,
      format: nil,
      message: nil,
      template_name: nil
    )
      @parameter_name = parameter_name
      @format         = format
      @template_name  = template_name

      super(
        details:,
        format:,
        message:        default_message(message),
        parameter_name:,
        template_name:
      )
    end

    # @return [String] the content format.
    attr_reader :format

    # @return [String, Symbol] the name of the missing parameter.
    attr_reader :parameter_name

    private

    def as_json_data
      super.merge(
        'format'         => format,
        'parameter_name' => parameter_name.to_s
      ).compact
    end

    def default_message(message)
      str = "missing parameter #{parameter_name.inspect}"

      if template_name?
        str = "#{str} for template #{template_name}"
        str = "#{str} with format #{format}" if format?
      elsif format?
        str = "#{str} for #{format} template"
      end

      return str unless message && !message.empty?

      "#{message} - #{str}"
    end

    def format? = format && !format.empty?

    def template_name? = template_name && !template_name.empty?
  end
end
