# frozen_string_literal: true

require 'cuprum/cli/integrations/async'

module Cuprum::Cli::Integrations::Async
  # Namespace for commands that rely on the Async integration.
  module Commands
    autoload :RSpecEachCommand,
      'cuprum/cli/integrations/async/commands/rspec_each_command'
  end
end
