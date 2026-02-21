# frozen_string_literal: true

require 'cuprum/cli/integrations/thor'
require 'cuprum/cli/integrations/thor/task'
require 'cuprum/cli/registry'

module Cuprum::Cli::Integrations::Thor
  # Registers CLI commands by name and adds as Thor tasks.
  class Registry < Cuprum::Cli::Registry
    # Registers the command with the registry.
    #
    # Also registers a Thor task with compatible parameters and metadata.
    #
    # @param command [Class] the command class to register.
    # @param name [String] the name under which to register the command.
    #   Defaults to the value of command.full_name.
    #
    # @raise [NameError] if a command is already registered with that name.
    #
    # @return [self]
    def register(command, name: nil)
      super.tap do
        Cuprum::Cli::Integrations::Thor::Task::Builder
          .new(command)
          .build(full_name: name)
      end
    end
  end
end
