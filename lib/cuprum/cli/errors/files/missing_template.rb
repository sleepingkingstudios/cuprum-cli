# frozen_string_literal: true

require 'cuprum/error'

require 'cuprum/cli/errors/files'

module Cuprum::Cli::Errors::Files
  # Error returned when unable to load a template.
  class MissingTemplate < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'cuprum.cli.errors.files.missing_template'

    # @param template_path [String] the expected template path.
    # @param message [String] an optional message to display.
    def initialize(template_path:, message: nil)
      @template_path = template_path

      super(message: default_message(message), template_path:)
    end

    # @return [String] the expected template path.
    attr_reader :template_path

    private

    def as_json_data = { 'template_path' => template_path }

    def default_message(message)
      str = "unable to load template #{template_path}"

      return str unless message && !message.empty?

      "#{message} - #{str}"
    end
  end
end
