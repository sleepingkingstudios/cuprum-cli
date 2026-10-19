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

    # @overload register(*commands, **config, &block)
    #   Registers the commands with the registry.
    #
    #   If given a block, transforms the command using the block. This can be
    #   used to customize the commands, such as applying a custom prefix or
    #   configuration options. If the block instead returns nil, that command
    #   will not be registered.
    #
    #   @param commands [Array<Class>] the command classes to register.
    #   @param config [Hash] options for configuring the command.
    #
    #   @option config arguments [Array] arguments to pass to the command on
    #     initialization.
    #   @option config description [String] the description for the command.
    #   @option config full_description [String] the full description for the
    #     command.
    #   @option config full_name [String] the name under which to register the
    #     command. Defaults to the value of command.full_name.
    #   @option config options [Hash] options to pass to the command on
    #     initialization.
    #
    #   @yieldparam command [Class] the original command class.
    #
    #   @yieldreturn [Class, nil] the command class to register. If nil is
    #     returned instead, nothing will be registered for the input command.
    #
    #   @raise [NameError] if a command is already registered with that name.
    #
    #   @return [self]
    #
    #   @example Register a command
    #     registry.register(ExampleCommand)
    #
    #     registry.commands.key?('example')
    #     #=> true
    #
    #   @example Register a command with configuration options
    #     registry.register ExampleCommand,
    #       full_name: 'scope:custom_command',
    #       options:   { option: 'value' }
    #
    #     registry.commands.key?('example')
    #     #=> false
    #     registry.commands.key?('scope:custom_command')
    #     #=> true
    #     registry.commands['scope:example_command'].option_values
    #     #=> { option: 'value' }
    #
    #   @example Register multiple commands with configuration options
    #     registry.register FirstCommand,
    #       SecondCommand,
    #       ThirdCommand,
    #       options: { shared: 'value' }
    #
    #     registry.commands.key?('first')
    #     #=> true
    #     registry.commands.key?('second')
    #     #=> true
    #     registry.commands.key?('third')
    #     #=> true
    #     registry.commands['first'].option_values
    #     #=> { shared: 'value' }
    #
    #   @example Register multiple commands and configure with a block
    #     registry.register(FirstCommand, SecondCommand, ThirdCommand) do |command|
    #       full_name = "scope:#{command.full_name}"
    #
    #       command.with_full_name(full_name)
    #     end
    #
    #     registry.commands.key?('scope:first')
    #     #=> true
    #     registry.commands.key?('scope:second')
    #     #=> true
    #     registry.commands.key?('scope:third')
    #     #=> true
    #
    #   @example Register multiple commands and filter with a block
    #     commands = [OneCommand, TwoCommand, ThreeCommand]
    #
    #     registry.register(commands) do |command|
    #       next unless command.full_name.start_with?('t')
    #
    #       command
    #     end
    #
    #     registry.commands.key?('one')
    #     #=> false
    #     registry.commands.key?('two')
    #     #=> true
    #     registry.commands.key?('three')
    #     #=> true
    def register(*commands, **config, &block)
      tools.assertions.validate_presence(commands, as: 'commands')

      commands
        .flatten
        .each { |command| validate_command(command) }
        .map  { |command| build_command(command, **config, &block) }
        .compact
        .each { |command| add_registered_command(command) }

      self
    end
    alias add register

    private

    def add_registered_command(command)
      validate_name(command.full_name)

      registered_commands[command.full_name] = command
    end

    def assign_command_properties( # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      command_class,
      parent_class,
      arguments: nil,
      options:   nil,
      **config
    )
      %i[description full_description full_name].each do |property|
        next unless config.key?(property) || parent_class.send(:"#{property}?")

        value = config.fetch(property, parent_class.send(property))

        tools.assertions.validate_presence(value, as: property)

        command_class.send(property, value)
      end

      arguments&.each do |argument|
        command_class.argument_value(argument)
      end

      options&.each do |option, value|
        command_class.option_value(option, value)
      end

      command_class
    end

    def build_command(parent_class, **config, &block)
      return parent_class unless block_given? || !config.empty?

      Class
        .new(parent_class)
        .then do |klass|
          assign_command_properties(klass, parent_class, **config)
        end # rubocop:disable Style/MultilineBlockChain
        .then { |klass| block_given? ? block.call(klass) : klass }
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
