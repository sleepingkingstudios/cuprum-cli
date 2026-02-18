# frozen_string_literal: true

require 'cuprum/cli'
require 'cuprum/cli/options'

module Cuprum::Cli
  # Data object representing a command option.
  Option = Data.define(
    :aliases,
    :default,
    :description,
    :name,
    :parameter_name,
    :required,
    :type
  ) do
    # @param name [String, Symbol] the name of the option.
    # @param aliases [Array<String, Symbol>] aliases for the option when parsing
    #   options from the command line.
    # @param default [Object, Proc] the default value for the option. If given
    #   and the value of the option is nil, sets the option value to the default
    #   value.
    # @param description [String] a short, human-readable description of the
    #   option.
    # @param parameter_name [String] a representation of the possible values for
    #   the option.
    # @param required [true, false] if true, raises an exception if the option
    #   is not provided to the command.
    # @param type [Class, String, Symbol] the expected type of the option value
    #   as a Class or class name. If given, raises an exception if the option
    #   value is not an instance of the type. Defaults to :string.
    def initialize( # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
      name:,
      aliases:        [],
      default:        nil,
      description:    nil,
      parameter_name: nil,
      required:       false,
      type:           :string
    )
      name     = name.to_sym
      aliases  = Array(aliases).compact.map { |obj| obj.to_s.tr('_', '-') }
      required = required ? true : false
      type     = type.to_sym if type.is_a?(String)

      super(
        aliases:,
        default:,
        description:,
        name:,
        parameter_name:,
        required:,
        type:
      )
    end

    alias_method :required?, :required

    # @overload def resolve(value)
    #   Validates the value for the current option.
    #
    #   If the value is nil, applies the option default (if any).
    #
    #   @param value [Object] the value to validate.
    #
    #   @return [Object] the validated option value.
    #
    #   @raise [Cuprum::Cli::Options::InvalidOptionError] if the value is
    #     missing (for a required option) or invalid.
    def resolve(original_value)
      value = original_value
      value = default_value if blank?(value)
      value = value.to_s    if value.is_a?(Symbol)

      return (type == :boolean ? false : nil) if value.nil? && !required?

      return value if valid_option?(value)

      raise Cuprum::Cli::Options::InvalidOptionError,
        invalid_option_message(original_value)
    end

    private

    def blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end

    def default_value
      default.is_a?(Proc) ? default.call : default
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

    def invalid_option_message(value)
      "invalid value for option :#{name} - expected #{expected_type}, " \
        "received #{value.inspect}"
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    def valid_option?(value)
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
  end
end
