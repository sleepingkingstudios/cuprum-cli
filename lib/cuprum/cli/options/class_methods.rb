# frozen_string_literal: true

require 'weakref'

require 'cuprum/cli/option'
require 'cuprum/cli/options'

module Cuprum::Cli::Options
  # Methods used to extend command class functionality for defining options.
  module ClassMethods
    # Helper class for defining command options.
    class Builder
      # @param command_class [Class] the command class.
      # @param defined_options [Hash{Symbol => Cuprum::Cli::Option}] the options
      #   defined for the command.
      def initialize(command_class:, defined_options:)
        @command_class   = command_class
        @defined_options = defined_options
      end

      # @return [Class] the command class.
      attr_reader :command_class

      # @return [Hash{Symbol => Cuprum::Cli::Option}] the options
      #   defined for the command.
      attr_reader :defined_options

      # (see Cuprum::Cli::Options::ClassMethods#option)
      def call(name, define_method: nil, define_predicate: nil, **options)
        option = Cuprum::Cli::Option.new(name:, **options)

        defined_options[option.name] = option

        define_method    = (options[:type] != :boolean) if define_method.nil?
        define_predicate = (options[:type] == :boolean) if define_predicate.nil?

        define_method_for(option)    if define_method
        define_predicate_for(option) if define_predicate

        option.name
      end

      private

      def define_method_for(option)
        command_class.define_method(option.name) { @options[option.name] }
      end

      def define_predicate_for(option)
        command_class.define_method(:"#{option.name}?") do
          value = @options[option.name]

          !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
        end
      end
    end

    # @overload option(name, aliases: [], default: nil, description: nil, required: false, type: :string, **options)
    #   Defines an option for the command class.
    #
    #   @param name [String, Symbol] the name of the option.
    #   @param aliases [Array<String, Symbol>] aliases for the option when
    #     parsing options from the command line.
    #   @param default [Object, Proc] the default value for the option. If given
    #     and the value of the option is nil, sets the option value to the
    #     default value.
    #   @param description [String] a short, human-readable description of the
    #     option.
    #   @param required [true, false] if true, raises an exception if the option
    #     is not provided to the command.
    #   @param type [Class, String, Symbol] the expected type of the option
    #     value as a Class or class name. If given, raises an exception if the
    #     option value is not an instance of the type. Defaults to :string.
    #   @param options [Hash] additional options for defining the option.
    #
    #   @option options define_method [true, false] if true, defines a reader
    #     method for the option. Defaults to false for boolean options and true
    #     for all other options.
    #   @option options define_predicate [true, false] if true, defines a
    #     predicate method for the option, which returns true if the option is
    #     not nil and not empty. Defaults to true for boolean options and false
    #     for all other options.
    def option(name, define_method: nil, define_predicate: nil, **)
      options_builder
        .call(name, define_method:, define_predicate:, **)
    end

    # The defined options, including options defined on ancestor classes.
    #
    # @return [Hash{Symbol => Cuprum::Cli::Option}] the defined options.
    def options
      ancestors.reduce({}) do |hsh, ancestor|
        return hsh if     ancestor == Cuprum::Cli::Command
        next   hsh unless ancestor.respond_to?(:defined_options, true)

        hsh.merge(ancestor.defined_options)
      end
    end

    # Validates the given option values against the defined class options.
    #
    # Also applies any default values from the defined options.
    #
    # @param values [Hash] the option values to resolve.
    #
    # @return [Hash] the option values with applied defaults.
    #
    # @raise [Cuprum::Cli::Options::UnknownOptionError] if any value does not
    #   have a corresponding defined option.
    # @raise [Cuprum::Cli::Options::InvalidOptionError] if any value does not
    #   match the expected option type, or any required value is missing.
    def resolve_options(**values)
      defined_options = options
      unknown_options = values.keys - defined_options.keys

      unless unknown_options.empty?
        raise Cuprum::Cli::Options::UnknownOptionError,
          unknown_options_message(defined_options:, unknown_options:)
      end

      defined_options.to_h do |key, option|
        [key, option.resolve(values[key])]
      end
    end

    protected

    def defined_options
      @defined_options ||= {}
    end

    def options_builder
      (
        @options_builder ||= WeakRef.new(
          Builder.new(command_class: self, defined_options:)
        )
      ).__getobj__
    rescue RefError
      # :nocov:
      @options_builder = WeakRef.new(
        Builder.new(command_class: self, defined_options:)
      )
      # :nocov:
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    def unknown_options_message(defined_options:, unknown_options:)
      counted =
        tools.integer_tools.pluralize(unknown_options.size, 'option')
      unknown = unknown_options.map(&:inspect).join(', ')
      message = "unrecognized #{counted} #{unknown} for #{name}"

      return message if defined_options.empty?

      valid_options = defined_options.keys.sort.map(&:inspect).join(', ')

      "#{message} - valid options are #{valid_options}"
    end
  end
end
