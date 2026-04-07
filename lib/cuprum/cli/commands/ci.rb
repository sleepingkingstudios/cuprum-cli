# frozen_string_literal: true

require 'cuprum/cli/commands'

module Cuprum::Cli::Commands
  # Namespace for commands used in continuous integration.
  module Ci
    autoload :Report,           'cuprum/cli/commands/ci/report'
    autoload :RSpecCommand,     'cuprum/cli/commands/ci/rspec_command'
    autoload :RSpecEachCommand, 'cuprum/cli/commands/ci/rspec_each_command'
  end
end
