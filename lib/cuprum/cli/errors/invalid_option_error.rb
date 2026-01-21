# frozen_string_literal: true

require 'cuprum/cli/errors'

module Cuprum::Cli::Errors
  # Exception raised when a command receives an invalid value for an option.
  class InvalidOptionError < StandardError; end
end
