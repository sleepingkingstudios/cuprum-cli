# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Registers CLI commands by name.
  class Registry
    # @return [Class, nil] the command registered with the given name, if any.
    def [](name)
      tools.assertions.validate_name(name, as: 'name')

      registered_commands[name]
    end

    # Returns a copy of the commands registered with the registry.
    #
    # @return [Hash{String => Class}] the registered commands.
    def commands
      registered_commands.dup.freeze
    end

    # Registers the command with the registry.
    #
    # @param command [Class] the command class to register.
    # @param arguments [Array] arguments to pass to the command on
    #   initialization.
    # @param options [Hash] options to pass to the command on initialization.
    # @param name [String] the name under which to register the command.
    #   Defaults to the value of command.full_name.
    #
    # @raise [NameError] if a command is already registered with that name.
    #
    # @return [self]
    def register(command, arguments: nil, name: nil, options: nil)
      validate_command(command)

      name ||= command.full_name

      validate_name(name)

      if present?(arguments) || present?(options)
        command = build_command(command, arguments:, options:)
      end

      registered_commands[name] = command

      self
    end

    private

    def build_command(command, arguments:, options:)
      Class.new(command).tap do |command_class|
        arguments&.each do |argument|
          command_class.argument_value(argument)
        end

        options&.each do |option, value|
          command_class.option_value(option, value)
        end
      end
    end

    def invalid_name_format_message
      'name does not match format category:sub_category:do_something'
    end

    def present?(value)
      return false if value.nil?

      return false unless value.respond_to?(:empty?) && !value.empty?

      true
    end

    def registered_commands = @registered_commands ||= {}

    def tools = SleepingKingStudios::Tools::Toolbelt.instance

    def validate_command(command)
      tools.assertions.validate_class(command, as: 'command')
      tools.assertions.validate_inherits_from(
        command,
        as:       'command',
        expected: Cuprum::Cli::Command
      )
    end

    def validate_name(name) # rubocop:disable Metrics/MethodLength
      tools.assertions.validate_name(name, as: 'name')
      tools.assertions.validate_matches(
        name,
        as:       'name',
        expected: Cuprum::Cli::Metadata::FULL_NAME_FORMAT,
        message:  invalid_name_format_message
      )

      return unless registered_commands.key?(name)

      command = registered_commands[name]
      message = "command already registered as #{name} - #{command.inspect}"

      raise NameError, message
    end
  end
end
