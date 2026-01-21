# frozen_string_literal: true

require 'cuprum/cli/errors'

module Cuprum::Cli::Errors
  # Exception raised when a command receives an unrecognized option.
  class UnknownOptionError < StandardError; end
end
