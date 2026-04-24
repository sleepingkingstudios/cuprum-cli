# frozen_string_literal: true

require 'cuprum/error'

require 'cuprum/cli/errors/files'

module Cuprum::Cli::Errors::Files
  # Error returned when an error occurs when generating templated content.
  class TemplateError < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'cuprum.cli.errors.files.template_error'

    # @param message [String] message describing the nature of the error.
    # @param details [String] additional information about the error.
    # @param template_name [String] the name of the rendered content, if any,
    def initialize(message:, details: nil, template_name: nil, **)
      @details       = details
      @template_name = template_name

      super
    end

    # @return [String] additional information about the error.
    attr_reader :details

    # @return [String] the name of the rendered content, if any,
    attr_reader :template_name

    private

    def as_json_data
      super
        .merge('details' => details, 'template_name' => template_name)
        .compact
    end
  end
end
