# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Utility for coercing raw string values to other literal types.
  module Coercion
    FALSY_VALUES = Set.new(%w[f false n no]).freeze
    private_constant :FALSY_VALUES

    INTEGER_PATTERN = /\A-?\d+([\d_,]+\d)?\z/i
    private_constant :INTEGER_PATTERN

    NULLISH_VALUES = Set.new(['', 'nil', 'null']).freeze
    private_constant :NULLISH_VALUES

    TRUTHY_VALUES = Set.new(%w[t true y yes]).freeze
    private_constant :TRUTHY_VALUES

    # Exception raised when trying to coerce an invalid value.
    class CoercionError < StandardError; end

    # Converts the value to a predicted type based on the value format.
    #
    # @param value [Object] the value to convert.
    #
    # @param [nil, true, false, Integer, String] the coerced value.
    def self.coerce(value)
      skip_validation = true

      return coerce_nil(value, skip_validation:)     if coerce_nil?(value)
      return coerce_boolean(value, skip_validation:) if coerce_boolean?(value)
      return coerce_integer(value, skip_validation:) if coerce_integer?(value)

      return value if value.is_a?(String)

      value.inspect
    end

    # @overload coerce_boolean(value)
    #   Converts the value to true or false.
    #
    #   @param value [Object] the value to convert.
    #
    #   @return [true, false] the coerced value.
    #
    #   @raise [CoercionError] if the value cannot be coerced to either true or
    #     false.
    def self.coerce_boolean(value, skip_validation: false)
      return false if value.nil?

      if !skip_validation && !coerce_boolean?(value)
        raise CoercionError,
          "unable to coerce #{value.inspect} to true or false"
      end

      value = value.downcase

      return false if FALSY_VALUES.include?(value)
      return true  if TRUTHY_VALUES.include?(value)

      nil
    end

    # @return [true, false] true if the value can be safely coerced to either
    #   true or false, otherwise false.
    def self.coerce_boolean?(value)
      return true if value.nil?
      return false unless value.is_a?(String)

      value = value.downcase

      FALSY_VALUES.include?(value) || TRUTHY_VALUES.include?(value)
    end

    # @overload coerce_integer(value)
    #   Converts the value to an Integer.
    #
    #   @param value [Object] the value to convert.
    #
    #   @return [Integer] the coerced value.
    #
    #   @raise [CoercionError] if the value cannot be coerced to an Integer.
    def self.coerce_integer(value, skip_validation: false)
      if !skip_validation && !coerce_integer?(value)
        raise CoercionError,
          "unable to coerce #{value.inspect} to an Integer"
      end

      value.tr('_,', '').to_i
    end

    # @return [true, false] true if the value can be safely coerced to an
    #   Integer, otherwise false.
    def self.coerce_integer?(value)
      return false unless value.is_a?(String)

      value = value.downcase

      INTEGER_PATTERN.match?(value)
    end

    # @overload coerce_nil(value)
    #   Converts the value to nil.
    #
    #   @param value [Object] the value to convert.
    #
    #   @return [nil] the coerced value.
    #
    #   @raise [CoercionError] if the value cannot be coerced to nil.
    def self.coerce_nil(value, skip_validation: false)
      return nil if value.nil?

      if !skip_validation && !coerce_nil?(value)
        raise CoercionError,
          "unable to coerce #{value.inspect} to nil"
      end

      nil
    end

    # @return [true, false] true if the value can be safely coerced to nil,
    #   otherwise false.
    def self.coerce_nil?(value)
      return true if value.nil?
      return false unless value.is_a?(String)

      NULLISH_VALUES.include?(value.downcase)
    end
  end
end
