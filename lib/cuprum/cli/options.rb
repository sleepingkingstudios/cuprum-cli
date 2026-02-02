# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Namespace for functionality that implements command options.
  module Options
    autoload :ClassMethods, 'cuprum/cli/options/class_methods'
    autoload :Quiet,        'cuprum/cli/options/quiet'

    # Exception raised when a command receives an invalid value for an option.
    class InvalidOptionError < StandardError; end

    # Exception raised when a command receives an unrecognized option.
    class UnknownOptionError < StandardError; end
  end
end
