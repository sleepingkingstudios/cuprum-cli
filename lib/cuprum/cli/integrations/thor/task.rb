# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbelt'
require 'sleeping_king_studios/tools/toolbox/subclass'
require 'thor'

require 'cuprum/cli/integrations/thor'

module Cuprum::Cli::Integrations::Thor
  # Thor task wrapping a Cuprum::Cli command.
  class Task < ::Thor
    extend SleepingKingStudios::Tools::Toolbox::Subclass

    # Ensures that the task exists with a non-zero status code on a failure.
    #
    # @return [true]
    def self.exit_on_failure? = true

    # @overload initialize(command_class, arguments = [], options = {}, config = {})
    #   @param command_class [Class] the command to execute.
    #   @param arguments [Array] the arguments passed by the Thor runtime.
    #   @param options [Hash] the options passed by the Thor runtime.
    #   @param config [Hash] additional configuration passed by the Thor
    #     runtime.
    def initialize(
      command_class,
      arguments = [],
      options   = {},
      config    = {},
      command_dependencies: {}
    )
      super(arguments, options, config)

      @command_class = command_class
      @command_dependencies = command_dependencies
    end

    # @return [Class] the command to execute.
    attr_reader :command_class

    no_commands do
      # Calls the wrapped Cuprum::Cli command with the parsed parameters.
      def call_command
        opts =
          SleepingKingStudios::Tools::Toolbelt
          .instance
          .hash_tools
          .convert_keys_to_symbols(options)

        command_class.new(**command_dependencies).call(*args, **opts)
      end
    end

    private

    attr_reader :command_dependencies
  end
end
