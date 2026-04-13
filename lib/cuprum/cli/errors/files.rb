# frozen_string_literal: true

require 'cuprum/cli/errors'

module Cuprum::Cli::Errors
  # Namespace for errors returned when creating or managing files.
  module Files
    autoload :FileNotWriteable, 'cuprum/cli/errors/files/file_not_writeable'
    autoload :MissingParameter, 'cuprum/cli/errors/files/missing_parameter'
    autoload :TemplateError,    'cuprum/cli/errors/files/template_error'
  end
end
