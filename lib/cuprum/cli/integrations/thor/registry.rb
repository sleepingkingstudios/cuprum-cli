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
    # @param config [Hash] options for configuring the command.
    #
    # @option config arguments [Array] arguments to pass to the command on
    #   initialization.
    # @option config description [String] the description for the command.
    # @option config full_description [String] the full description for the
    #   command.
    # @option config full_name [String] the name under which to register the
    #   command. Defaults to the value of command.full_name.
    # @option config options [Hash] options to pass to the command on
    #   initialization.
    #
    # @raise [NameError] if a command is already registered with that name.
    #
    # @return [self]
    def register(command, **config)
      super.tap do
        name    = config.fetch(:full_name, command.full_name)
        command = commands[name]

        Cuprum::Cli::Integrations::Thor::Task::Builder
          .new(command)
          .build(full_name: name)
      end
    end
  end
end
