# frozen_string_literal: true

require 'cuprum/cli/files'

module Cuprum::Cli::Files
  # Namespace for errors returned when creating or managing files.
  module Errors
    autoload :FileNotWriteable,
      'cuprum/cli/files/errors/file_not_writeable'
    autoload :GeneratorError,
      'cuprum/cli/files/errors/generator_error'
    autoload :MissingParameter,
      'cuprum/cli/files/errors/missing_parameter'
    autoload :MissingTemplate,
      'cuprum/cli/files/errors/missing_template'
    autoload :TemplateError,
      'cuprum/cli/files/errors/template_error'
  end
end
