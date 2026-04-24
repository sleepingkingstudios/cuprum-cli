# frozen_string_literal: true

require 'cuprum/error'

require 'cuprum/cli/errors/files'

module Cuprum::Cli::Errors::Files
  # Error returned when attempting to generate a file in an invalid location.
  class FileNotWriteable < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'cuprum.cli.errors.files.file_not_writeable'

    # @param file_path [String] the path to the expected file.
    # @param message [String] message describing the nature of the error.
    # @param reason [String] additional details on the error.
    def initialize(file_path:, message: nil, reason: nil)
      @file_path = file_path
      @reason    = reason
      message    = default_message(file_path:, message:, reason:)

      super
    end

    # @return [String] the path to the expected file.
    attr_reader :file_path

    # @return [String] additional details on the error.
    attr_reader :reason

    private

    def as_json_data = { 'file_path' => file_path, 'reason' => reason }.compact

    def default_message(file_path:, message:, reason:)
      message ||= "unable to write file #{file_path}"

      return message unless reason

      "#{message} - #{reason}"
    end
  end
end
