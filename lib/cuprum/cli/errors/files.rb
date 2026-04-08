# frozen_string_literal: true

require 'cuprum/cli/errors'

module Cuprum::Cli::Errors
  # Namespace for errors returned when creating or managing files.
  module Files
    autoload :MissingParameter, 'cuprum/cli/errors/files/missing_parameter'
    autoload :TemplateError,    'cuprum/cli/errors/files/template_error'
  end
end
