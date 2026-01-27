# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Namespace for functionality that implements command positional arguments.
  module Arguments
    autoload :ClassMethods, 'cuprum/cli/arguments/class_methods'

    # Exception raised when a command receives too many positional arguments.
    class ExtraArgumentsError < StandardError; end

    # Exception raised when a command receives an invalid value for an argument.
    class InvalidArgumentError < StandardError; end
  end
end
