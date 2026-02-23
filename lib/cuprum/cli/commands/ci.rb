# frozen_string_literal: true

require 'cuprum/cli/commands'

module Cuprum::Cli::Commands
  # Namespace for commands used in continuous integration.
  module Ci
    autoload :Report, 'cuprum/cli/commands/ci/report'
  end
end
