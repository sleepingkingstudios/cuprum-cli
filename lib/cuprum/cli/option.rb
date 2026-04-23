# frozen_string_literal: true

require 'cuprum/cli'
require 'cuprum/cli/options'

module Cuprum::Cli # rubocop:disable Metrics/ModuleLength
  # Data object representing a command option.
  Option = Data.define(
    :aliases,
    :default,
    :description,
    :name,
    :parameter_name,
    :required,
    :type,
    :variadic
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
    # @param variadic [true, false] if true, the option is variadic and
    #   represents an hash of options provided to the command. Defaults to
    #   false.
    def initialize( # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
      name:,
      aliases:        [],
      default:        nil,
      description:    nil,
      parameter_name: nil,
      required:       false,
      type:           :string,
      variadic:       false
    )
      name     = name.to_sym
      aliases  = Array(aliases).compact.map { |obj| obj.to_s.tr('_', '-') }
      required = required ? true : false
      type     = type.to_sym if type.is_a?(String)
      variadic = variadic ? true : false

      super(
        aliases:,
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

      return default_value_for_type if value.nil? && !required?
      return value                  if valid_option?(value)

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

    def default_value_for_type
      return {} if variadic?

      return false if type == :boolean && !required?

      nil
    end

    def expected_hash_type
      message = required? ? 'a non-empty Hash of' : 'a Hash of'

      return "#{message} true or false values" if type == :boolean

      plural_type =
        tools.string_tools.pluralize(type.is_a?(Class) ? type.name : type)

      "#{message} #{tools.string_tools.camelize(plural_type)}"
    end

    def expected_type
      return expected_hash_type if variadic?

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
      return validate_option(value) unless variadic?

      return false unless value.is_a?(Hash)
      return false if required? && value.empty?

      value.each_value.all? { |item| validate_option(item) }
    end

    def validate_option(value) # rubocop:disable Naming/PredicateMethod
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
