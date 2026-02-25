# frozen_string_literal: true

require 'weakref'

require 'cuprum/cli/arguments'

module Cuprum::Cli::Arguments
  # Methods used to extend command class functionality for defining arguments.
  module ClassMethods
    # Helper class for defining command arguments.
    class Builder
      # @param command_class [Class] the command class.
      # @param defined_arguments [Array<Cuprum::Cli::Argument>] the arguments
      #   defined for the command.
      def initialize(command_class:, defined_arguments:)
        @command_class     = command_class
        @defined_arguments = defined_arguments
      end

      # @return [Class] the command class.
      attr_reader :command_class

      # @return [Array<Cuprum::Cli::Argument>] the arguments defined for the
      #   command.
      attr_reader :defined_arguments

      # (see Cuprum::Cli::Arguments::ClassMethods#argument)
      def call(name, define_method: nil, define_predicate: nil, **options)
        argument = Cuprum::Cli::Argument.new(name:, **options)

        defined_arguments << argument

        define_method    = (options[:type] != :boolean) if define_method.nil?
        define_predicate = (options[:type] == :boolean) if define_predicate.nil?

        define_method_for(argument)    if define_method
        define_predicate_for(argument) if define_predicate

        argument.name
      end

      private

      def define_method_for(argument)
        command_class.define_method(argument.name) { @arguments[argument.name] }
      end

      def define_predicate_for(argument)
        command_class.define_method(:"#{argument.name}?") do
          value = @arguments[argument.name]

          return false if value.nil? || value == false

          !(value.respond_to?(:empty?) && value.empty?)
        end
      end
    end

    # @private
    class VariadicArgumentsResolver
      def initialize(defined_arguments)
        @defined_arguments = defined_arguments
        @variadic_index    = defined_arguments.index(&:variadic?)
        @variadic_argument = defined_arguments[variadic_index]
        @before_arguments  = defined_arguments[...variadic_index]
        @after_arguments   = defined_arguments[(1 + variadic_index)..]
        @resolved          = {}
      end

      def call(*values)
        values = resolve_before(values)
        values = resolve_after(values)

        resolved[variadic_argument.name] = values

        resolved
      end

      private

      attr_reader :after_arguments

      attr_reader :before_arguments

      attr_reader :resolved

      attr_reader :variadic_argument

      attr_reader :variadic_index

      def resolve_after(values) # rubocop:disable Metrics/AbcSize
        extra_count = values.count - after_arguments.count

        if extra_count.negative?
          values.concat(Array.new(-extra_count))

          extra_count = 0
        end

        after_arguments&.each&.with_index(extra_count) do |argument, index|
          resolved[argument.name] = argument.resolve(values[index])
        end

        values[...extra_count]
      end

      def resolve_before(values)
        before_arguments&.each&.with_index do |argument, index|
          resolved[argument.name] = argument.resolve(values[index])
        end

        values[before_arguments.count...] || []
      end
    end
    private_constant :VariadicArgumentsResolver

    # @overload argument(name, default: nil, description: nil, required: false, type: :string, variadic: false, **options)
    #   Defines an argument for the command class.
    #
    #   @param name [String, Symbol] the name of the argument.
    #   @param default [Object, Proc] the default value for the argument. If
    #     given and the value of the argument is nil, sets the argument value to
    #     the default value.
    #   @param description [String] a short, human-readable description of the
    #     argument.
    #   @param required [true, false] if true, raises an exception if the
    #     argument is not provided to the command.
    #   @param type [Class, String, Symbol] the expected type of the argument
    #     value as a Class or class name. If given, raises an exception if the
    #     argument value is not an instance of the type. Defaults to :string.
    #   @param variadic [true, false] if true, the argument is variadic and
    #     represents an array of arguments provided to the command. Defaults to
    #     false.
    #   @param options [Hash] additional options for defining the argument.
    #
    #   @option options define_method [true, false] if true, defines a reader
    #     method for the argument. Defaults to false for boolean arguments and
    #     true for all other arguments.
    #   @option options define_predicate [true, false] if true, defines a
    #     predicate method for the argument, which returns true if the argument
    #     is not nil and not empty. Defaults to true for boolean arguments and
    #     false for all other arguments.
    #
    #   @raise [ArgumentError] if variadic is true and the command already
    #     defines a variadic argument.
    def argument(name, define_method: nil, define_predicate: nil, **)
      handle_multiple_variadic_arguments(**)

      arguments_builder.call(name, define_method:, define_predicate:, **)
    end

    # @overload arguments()
    #   The defined arguments for the command class.
    #
    #   @return [Array<Cuprum::Cli::Argument>] the defined arguments.
    #
    # @overload arguments(name, default: nil, description: nil, required: false, type: :string, **options)
    #   Defines a variadic argument for the command class.
    #
    #   @param name [String, Symbol] the name of the argument.
    #   @param default [Object, Proc] the default value for the argument. If
    #     given and the value of the argument is nil, sets the argument value to
    #     the default value.
    #   @param description [String] a short, human-readable description of the
    #     argument.
    #   @param required [true, false] if true, raises an exception if the
    #     argument is not provided to the command.
    #   @param type [Class, String, Symbol] the expected type of the argument
    #     value as a Class or class name. If given, raises an exception if the
    #     argument value is not an instance of the type. Defaults to :string.
    #   @param options [Hash] additional options for defining the argument.
    #
    #   @option options define_method [true, false] if true, defines a reader
    #     method for the argument. Defaults to false for boolean arguments and
    #     true for all other arguments.
    #   @option options define_predicate [true, false] if true, defines a
    #     predicate method for the argument, which returns true if the argument
    #     is not nil and not empty. Defaults to true for boolean arguments and
    #     false for all other arguments.
    def arguments(name = nil, **)
      if name.nil?
        return defined_arguments unless defined_arguments.empty?

        return superclass.arguments if superclass.respond_to?(:arguments)

        return []
      end

      argument(name, **, variadic: true)
    end

    # Validates the given argument values against the defined class arguments.
    #
    # Also applies any default values from the defined arguments.
    #
    # @param values [Array] the arguments values to resolve.
    #
    # @return [Array] the arguments values with applied defaults.
    #
    # @raise [Cuprum::Cli::Arguments::ExtraArgumentsError] if provided more
    #   arguments than the command class defines arguments.
    # @raise [Cuprum::Cli::Arguments::InvalidArgumentError] if any value does
    #   not match the expected argument type, or any required value is missing.
    def resolve_arguments(*values) # rubocop:disable Metrics/MethodLength
      defined_arguments = arguments

      if defined_arguments.any?(&:variadic?)
        return VariadicArgumentsResolver.new(defined_arguments).call(*values)
      end

      if values.size > defined_arguments.size
        raise Cuprum::Cli::Arguments::ExtraArgumentsError,
          extra_arguments_message(values.size)
      end

      defined_arguments.each.with_index.to_h do |argument, index|
        [argument.name, argument.resolve(values[index])]
      end
    end

    private

    def arguments_builder
      (
        @arguments_builder ||= WeakRef.new(
          Builder.new(command_class: self, defined_arguments:)
        )
      ).__getobj__
    rescue RefError
      # :nocov:
      @arguments_builder = WeakRef.new(
        Builder.new(command_class: self, defined_arguments:)
      )
      # :nocov:
    end

    def defined_arguments
      @defined_arguments ||= []
    end

    def extra_arguments_message(count)
      total_count   = defined_arguments.size
      last_required = (arguments.rindex(&:required?) || -1) + 1
      expected      =
        last_required == total_count ? total_count : last_required..total_count

      "wrong number of arguments (given #{count}, expected #{expected})"
    end

    def handle_multiple_variadic_arguments(variadic: false, **)
      return unless variadic

      matching = defined_arguments.find(&:variadic?)

      return unless matching

      message = "command already defines variadic argument :#{matching.name}"

      raise ArgumentError, message
    end
  end
end
