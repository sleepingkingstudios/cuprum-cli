# frozen_string_literal: true

require 'cuprum/cli'
require 'cuprum/cli/arguments'

module Cuprum::Cli # rubocop:disable Metrics/ModuleLength
  # Data object representing a positional command argument.
  Argument = Data.define(
    :default,
    :description,
    :name,
    :parameter_name,
    :required,
    :type,
    :variadic
  ) do
    # @param name [String, Symbol] the name of the argument.
    # @param default [Object, Proc] the default value for the argument. If given
    #   and the value of the argument is nil, sets the argument value to the
    #   default value.
    # @param description [String] a short, human-readable description of the
    #   argument.
    # @param parameter_name [String] a representation of the possible values for
    #   the argument.
    # @param required [true, false] if true, raises an exception if the argument
    #   is not provided to the command.
    # @param type [Class, String, Symbol] the expected type of the argument
    #   value as a Class or class name. If given, raises an exception if the
    #   argument value is not an instance of the type. Defaults to :string.
    # @param variadic [true, false] if true, the argument is variadic and
    #   represents an array of arguments provided to the command. Defaults to
    #   false.
    def initialize( # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
      name:,
      default:        nil,
      description:    nil,
      parameter_name: nil,
      required:       false,
      type:           :string,
      variadic:       false
    )
      name     = name.to_sym
      required = required ? true : false
      type     = type.to_sym if type.is_a?(String)
      variadic = variadic ? true : false

      super(
        default:,
        description:,
        name:,
        parameter_name:,
        required:,
        type:,
        variadic:
      )
    end

    alias_method :required?, :required

    alias_method :variadic?, :variadic

    # @overload def resolve(value)
    #   Validates the value for the current argument.
    #
    #   If the value is nil, applies the argument default (if any).
    #
    #   @param value [Object] the value to validate.
    #
    #   @return [Object] the validated argument value.
    #
    #   @raise [Cuprum::Cli::Arguments::InvalidArgumentError] if the value is
    #     missing (for a required argument) or invalid.
    def resolve(original_value) # rubocop:disable Metrics/CyclomaticComplexity
      return resolve_variadic(original_value) if variadic?

      value = original_value
      value = default_value if blank?(value)
      value = value.to_s    if value.is_a?(Symbol)

      return (type == :boolean ? false : nil) if value.nil? && !required?

      return value if valid_argument?(value)

      raise Cuprum::Cli::Arguments::InvalidArgumentError,
        invalid_argument_message(original_value)
    end

    private

    def blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end

    def default_value
      default.is_a?(Proc) ? default.call : default
    end

    def expected_array_type # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      message = required? ? 'a non-empty Array of' : 'an Array of'

      case type
      when :boolean
        "#{message} true or false"
      when Class
        name = tools.string_tools.pluralize(type.name)

        "#{message} #{tools.string_tools.camelize(name)}"
      else
        name = tools.string_tools.pluralize(type.to_s)

        "#{message} #{tools.string_tools.camelize(name)}"
      end
    end

    def expected_type
      case type
      when :boolean
        'true or false'
      when Class
        "an instance of #{type.name}"
      else
        "an instance of #{tools.string_tools.camelize(type.to_s)}"
      end
    end

    def invalid_argument_message(value)
      "invalid value for argument :#{name} - expected #{expected_type}, " \
        "received #{value.inspect}"
    end

    def invalid_variadic_argument_message(value)
      "invalid value for variadic argument :#{name} - expected " \
        "#{expected_array_type}, received #{value.inspect}"
    end

    def resolve_variadic(original_value)
      value = original_value
      value = default_value if blank?(value)

      return [] if value.nil? && !required?

      return value if valid_arguments?(value)

      raise Cuprum::Cli::Arguments::InvalidArgumentError,
        invalid_variadic_argument_message(original_value)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    def valid_argument?(value)
      case type
      when :boolean
        value == true || value == false # rubocop:disable Style/MultipleComparison
      when Class
        value.is_a?(type)
      else
        expected = tools.string_tools.camelize(type.to_s)
        expected = Object.const_get(expected)

        value.is_a?(expected)
      end
    end

    def valid_arguments?(value)
      return false unless value.is_a?(Array)

      value.all? { |item| valid_argument?(item) }
    end
  end
end
