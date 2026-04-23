# frozen_string_literal: true

require 'cuprum/cli/integrations/thor'

module Cuprum::Cli::Integrations::Thor
  # Utility for parsing command-line arguments captured by Thor tasks.
  #
  # Any unrecognized command line flags or options are appended as-is to the
  # arguments array by Thor. Therefore, to handle cases such as variadic options
  # where flags or options cannot be pre-parsed by Thor, we need an additional
  # parsing step to pull any remaining flags or options out of the arguments.
  #
  # This parser supports the following formats:
  #
  # - `-a`, `--all`: Sets the `a` or `all` flag to `true`.
  # - `-abc`: Sets the `a`, `b`, and `c` flags to `true`.
  # - `--skip-all`, `--no-all`: Sets the `a` flag to `false`.
  # - `-a=value`, `--a=value`: Sets the `a` option to `"value"`.
  #
  # The following formats are specifically *not* supported:
  #
  # - `--foo bar`: `--foo` is assumed to be a flag, `bar` is assumed to be a
  #   positional argument.
  # - `--str[]=foo --str[]=bar`: Array arguments are not supported.
  # - `--str[foo]=foo --str[bar]=bar`: Hash arguments are not supported.
  #
  # In addition, parsed option values are coerced into their most likely
  # intended types.
  class ArgumentsParser
    # Parses the given argument inputs into arguments and options.
    #
    # @param inputs [Array<String>] the arguments captured by Thor.
    #
    # @return [Array<Array<String>, Hash<Symbol=>Object>] the parsed arguments
    #   and options.
    def call(*inputs)
      raw_options, arguments = inputs.partition { |str| str.start_with?('-') }

      [arguments, parse_options(raw_options)]
    end

    private

    def coerce_value(raw_value)
      Cuprum::Cli::Coercion.coerce(raw_value)
    end

    def grouped_flags?(raw_key)
      return false if raw_key.start_with?('--')

      raw_key.length > 2
    end

    def normalize_flag_key(raw_key)
      return raw_key[5..] if raw_key.start_with?('--no-')
      return raw_key[7..] if raw_key.start_with?('--skip-')
      return raw_key[2..] if raw_key.start_with?('--')

      raw_key[1..]
    end

    def normalize_option_key(raw_key)
      return raw_key[2..] if raw_key.start_with?('--')

      raw_key[1..]
    end

    def parse_flag_value(raw_key) # rubocop:disable Naming/PredicateMethod
      return false if raw_key.start_with?('--no-')
      return false if raw_key.start_with?('--skip-')

      true
    end

    def parse_option(raw_key, raw_value) # rubocop:disable Metrics/MethodLength
      if raw_value.nil? && grouped_flags?(raw_key)
        raw_key[1..].chars.to_h { |char| [char.to_sym, true] }
      elsif raw_value.nil?
        key   = normalize_flag_key(raw_key)
        value = parse_flag_value(raw_key)

        { key.to_sym => value }
      else
        key   = normalize_option_key(raw_key)
        value = coerce_value(raw_value)

        { key.to_sym => value }
      end
    end

    def parse_options(raw_options)
      raw_options.reduce({}) do |options, input|
        raw_key, raw_value = input.split('=')

        options.merge(parse_option(raw_key, raw_value))
      end
    end
  end
end
