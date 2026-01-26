# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Namespace for functionality that implements command options.
  module Arguments
    # Exception raised when a command receives an invalid value for an argument.
    class InvalidArgumentError < StandardError; end
  end
end
