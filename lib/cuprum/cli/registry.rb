# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Registers CLI commands by name.
  class Registry
    # @return [Class, nil] the command registered with the given name, if any.
    def [](name)
      tools.assertions.validate_name(name, as: 'full_name')

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
      validate_command(command)

      name = config.fetch(:full_name, command.full_name)

      validate_name(name)

      command = build_command(command, **config) if any_present?(config)

      registered_commands[name] = command

      self
    end

    private

    def any_present?(config)
      return false if config.empty?

      config.each_value.any? { |value| present?(value) }
    end

    def build_command( # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/ParameterLists
      command,
      arguments:        nil,
      description:      nil,
      full_description: nil,
      full_name:        nil,
      options:          nil,
      **
    )
      Class.new(command).tap do |command_class|
        command_class.description(description) if present?(description)

        command_class.full_name(full_name) if present?(full_name)

        if present?(full_description)
          command_class.full_description(full_description)
        end

        arguments&.each do |argument|
          command_class.argument_value(argument)
        end

        options&.each do |option, value|
          command_class.option_value(option, value)
        end
      end
    end

    def command_name(command)
      command
        .ancestors
        .find { |ancestor| ancestor.is_a?(Class) && ancestor.name }
        .name
    end

    def invalid_name_format_message
      'full_name does not match format category:sub_category:do_something'
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
      tools.assertions.validate_name(name, as: 'full_name')
      tools.assertions.validate_matches(
        name,
        as:       'full_name',
        expected: Cuprum::Cli::Metadata::FULL_NAME_FORMAT,
        message:  invalid_name_format_message
      )

      return unless registered_commands.key?(name)

      command = registered_commands[name]
      message =
        "command already registered as #{name} - #{command_name(command)}"

      raise NameError, message
    end
  end
end
