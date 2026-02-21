# frozen_string_literal: true

require 'forwardable'

require 'sleeping_king_studios/tools/toolbelt'
require 'sleeping_king_studios/tools/toolbox/subclass'
require 'thor'

require 'cuprum/cli/integrations/thor'

module Cuprum::Cli::Integrations::Thor
  # Thor task wrapping a Cuprum::Cli command.
  class Task < ::Thor
    extend SleepingKingStudios::Tools::Toolbox::Subclass

    # Generates a Thor::Task wrapping a Cuprum::Cli command class.
    class Builder
      extend Forwardable

      NUMERIC_TYPES = Set.new(%w[big_decimal integer float]).freeze
      private_constant :NUMERIC_TYPES

      # @param command_class [Class] the command to execute.
      def initialize(command_class)
        validate_command_class(command_class)

        @command_class = command_class
        @full_name     = nil
      end

      # @return [Class] the command to execute.
      attr_reader :command_class

      def_delegators :@command_class,
        :arguments,
        :description,
        :full_description,
        :full_description?

      # Generates a Thor::Task wrapping the command class.
      #
      # The generated task will be assigned Thor metadata automatically, based
      # on the configuration of the command class.
      #
      # @return [Class] the generated Task class.
      def build(full_name: nil)
        @full_name = full_name || command_class.full_name

        tools.assertions.validate_name(@full_name, as: 'full_name')

        Cuprum::Cli::Integrations::Thor::Task
          .subclass(command_class)
          .tap do |task|
            apply_metadata(task)

            task.alias_method short_name, :call_command
          end
      end

      private

      attr_reader :full_name

      def apply_arguments(task)
        command_class.arguments.each do |argument|
          params = {
            banner:   argument.parameter_name || argument.name.to_s.upcase,
            desc:     argument.description,
            optional: !argument.required?,
            type:     parameter_type(argument)
          }

          task.argument(argument.name, **params)
        end
      end

      def apply_options(task)
        command_class.options.each_value do |option|
          params = {
            aliases:  option.aliases,
            banner:   option.parameter_name || option.name.to_s.upcase,
            desc:     option.description,
            required: option.required?,
            type:     parameter_type(option)
          }

          task.option(option.name, **params)
        end
      end

      def apply_metadata(task)
        task.namespace(namespace)
        task.desc(signature, description)

        task.long_desc(full_description) if full_description?

        apply_arguments(task)
        apply_options(task)

        task
      end

      def argument_signature(argument)
        signature = argument.parameter_name || argument.name.to_s.upcase

        argument.variadic ? " ...#{signature}" : " #{signature}"
      end

      def arguments_signature
        arguments.map { |argument| argument_signature(argument) }.join
      end

      def namespace
        return 'default' if full_name.nil? || !full_name.include?(':')

        full_name&.sub(/:[\w_]+\z/, '')
      end

      def parameter_type(parameter)
        if parameter.is_a?(Cuprum::Cli::Argument) && parameter.variadic?
          return :array
        end

        type = parameter.type
        type = type.name if type.is_a?(Class)
        type = tools.string_tools.underscore(type)

        return :numeric if NUMERIC_TYPES.include?(type)

        type.to_sym
      end

      def short_name = full_name&.split(':')&.last

      def signature
        "#{short_name}#{arguments_signature}"
      end

      def tools
        SleepingKingStudios::Tools::Toolbelt.instance
      end

      def validate_command_class(command_class, as: 'command_class')
        tools.assertions.validate_class(command_class, as:)
        tools.assertions.validate_inherits_from(
          command_class,
          as:,
          expected: Cuprum::Cli::Command
        )

        validate_command_description(command_class, as:)
      end

      def validate_command_description(command_class, as:)
        description = command_class.description

        return unless description.nil? || description.empty?

        raise ArgumentError, "#{as} does not have a description"
      end
    end

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
