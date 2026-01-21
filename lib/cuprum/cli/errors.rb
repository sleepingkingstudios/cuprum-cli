# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Namespace for exceptions raised by Cuprum::Cli.
  module Errors
    autoload :InvalidOptionError, 'cuprum/cli/errors/invalid_option_error'
    autoload :UnknownOptionError, 'cuprum/cli/errors/unknown_option_error'
  end
end
