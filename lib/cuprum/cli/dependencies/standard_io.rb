# frozen_string_literal: true

require 'cuprum/cli/dependencies'

module Cuprum::Cli::Dependencies
  # Utility wrapping standard input, output, and error IO streams.
  class StandardIo
    autoload :Helpers, 'cuprum/cli/dependencies/standard_io/helpers'
    autoload :Mock,    'cuprum/cli/dependencies/standard_io/mock'

    ANSI_COLORS = {
      'black'  => 0,
      'blue'   => 34,
      'green'  => 32,
      'purple' => 35,
      'red'    => 31,
      'yellow' => 33
    }.freeze
    private_constant :ANSI_COLORS

    # @param error_stream [IO] the error stream. Defaults to $stderr.
    # @param input_stream [IO] the input stream. Defaults to $stdin.
    # @param output_stream [IO] the output stream. Defaulst to $stdout.
    def initialize(
      error_stream:  $stderr,
      input_stream:  $stdin,
      output_stream: $stdout
    )
      @error_stream  = error_stream
      @input_stream  = input_stream
      @output_stream = output_stream
    end

    # Wraps the text in an ANSI color escape code.
    #
    # @param text [String] the text to colorize.
    # @param color [String] the color to apply.
    #
    # @return [String] the colorized string.
    #
    # @raise [KeyError] if the requested color does not have an escape code.
    def color(text, color)
      color_code = ANSI_COLORS.fetch(color.to_s)

      "\e[#{color_code}m#{text}\e[0m"
    end

    # Requests a newline-terminated string from the input stream.
    #
    # @return [String] the returned input string.
    def read_input
      input_stream.gets
    end

    # Writes the given message to the error stream.
    #
    # If no error message is given, prints a newline only.
    #
    # @param message [String, nil] the message to write.
    # @param newline [true, false] if true, appends a newline to the message if
    #   it does not have a newline. Defaults to true.
    #
    # @return [nil]
    def write_error(message = nil, newline: true)
      newline ? error_stream.puts(message) : error_stream.print(message)
    end

    # Writes the given message to the output stream.
    #
    # If no message is given, prints a newline only.
    #
    # @param message [String, nil] the message to write.
    # @param newline [true, false] if true, appends a newline to the message if
    #   it does not have a newline. Defaults to true.
    #
    # @return [nil]
    def write_output(message = nil, newline: true)
      newline ? output_stream.puts(message) : output_stream.print(message)
    end

    private

    attr_reader :error_stream

    attr_reader :input_stream

    attr_reader :output_stream
  end
end
