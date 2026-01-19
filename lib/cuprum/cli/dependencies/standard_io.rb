# frozen_string_literal: true

require 'cuprum/cli/dependencies'

module Cuprum::Cli::Dependencies
  # Utility wrapping standard input, output, and error IO streams.
  class StandardIo
    # String input values that will be mapped to a boolean false.
    FALSY_VALUES = Set.new(%w[f false n no]).freeze

    # Pattern matching a valid integer input.
    INTEGER_PATTERN = /\A-?\d+([\d_,]+\d)?\z/

    # String input values that will be mapped to a boolean true.
    TRUTHY_VALUES = Set.new(%w[t true y yes]).freeze

    # @param error [IO] the error stream. Defaults to $stderr.
    # @param input [IO] the input stream. Defaults to $stdin.
    # @param output [IO] the output stream. Defaulst to $stdout.
    def initialize(error: $stderr, input: $stdin, output: $stdout)
      @error  = error
      @input  = input
      @output = output
    end

    # @overload ask(prompt = nil, caret: true, format: nil, strip: true, **options)
    #   Requests an input from the input stream.
    #
    #   @param prompt [String, nil] the prompt to display to the user, if any.
    #   @param options [Hash] options for requesting the input.
    #
    #   @option options caret [true, false] if true, prints a caret "> " to the
    #     output stream after the prompt. Defaults to true when the newline
    #     option is true, otherwise false.
    #   @option options format [String, Symbol] the expected format of the
    #     input. Valid values are :string (the default), :boolean, and :integer.
    #     The input string will be transformed into the given format, or an
    #     exception raised if the value cannot be transformed.
    #   @option options newline [true, false] if true, a newline will be printed
    #     after the prompt if a prompt is given.
    #   @option options strip [true, false] if true, strips the trailing newline
    #     from the input. Defaults to true.
    #
    #   @return [String, Integer, true, false, nil] the received and formatted
    #     input value, or nil if the input value was empty.
    def ask(prompt = nil, caret: nil, format: nil, newline: true, strip: true, **) # rubocop:disable Metrics/ParameterLists
      validate_prompt(prompt)
      display_prompt(caret:, newline:, prompt:)

      value = input.gets&.then { |str| strip ? str.strip : str }

      return if value.nil? || value.empty?
      return value if format.nil?

      send(:"format_#{format}", value)
    end

    # @overload say(message, newline: true, quiet: false, verbose: false, **options)
    #   Prints a message to the output stream.
    #
    #   @param message [String] the message to print.
    #   @param options [Hash] options for printing the message.
    #
    #   @option options newline [true, false] if true, appends a newline to the
    #     message if the message does not end with a newline. Defaults to true.
    #   @option options quiet [true, false] if true, prints the message even if
    #     the command has the :quiet option enabled. Defaults to false. Ignored
    #     if
    #     the command does not support the :quiet option.
    #   @option options verbose [true, false] if true, prints the message only
    #     if the command has the :verbose option enabled. Defaults to false.
    #     Ignored if the command does not support the :verbose option.
    #
    #   @return [nil]
    def say(message, newline: true, **)
      validate_message(message)

      newline ? output.puts(message) : output.print(message)
    end

    # @overload warn(message, **options)
    #   Prints a message to the error stream.
    #
    #   @param message [String] the message to print.
    #   @param options [Hash] options for printing the message.
    #
    #   @option options newline [true, false] if true, appends a newline to the
    #     message if the message does not end with a newline. Defaults to true.
    #
    #   @return [nil]
    def warn(message, newline: true, **)
      validate_message(message)

      newline ? error.puts(message) : error.print(message)
    end

    private

    attr_reader :error

    attr_reader :input

    attr_reader :output

    def display_prompt(caret:, newline:, prompt:)
      if prompt
        newline ? output.puts(prompt) : output.print(prompt)
      end

      output.print '> ' if caret.nil? ? newline : caret
    end

    def format_boolean(value)
      lower = value.downcase.strip

      return false if FALSY_VALUES.include?(lower)
      return true  if TRUTHY_VALUES.include?(lower)

      nil
    end

    def format_integer(value)
      return unless INTEGER_PATTERN.match?(value)

      value.tr('_,', '').to_i
    end

    def format_string(value) = value

    def tools = SleepingKingStudios::Tools::Toolbelt.instance

    def validate_message(message)
      tools.assertions.validate_instance_of(
        message,
        as:       'message',
        expected: String
      )
    end

    def validate_prompt(prompt)
      return if prompt.nil?

      tools.assertions.validate_instance_of(
        prompt,
        as:       'prompt',
        expected: String
      )
      tools.assertions.validate_presence(prompt, as: 'prompt')
    end
  end
end
