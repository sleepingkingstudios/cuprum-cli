# frozen_string_literal: true

require 'json'

require 'cuprum/cli/command'
require 'cuprum/cli/commands'

module Cuprum::Cli::Commands
  # Outputs the arguments and options passed to the command.
  class EchoCommand < Cuprum::Cli::Command
    dependency :file_system
    dependency :standard_io

    description 'Outputs the arguments and options passed to the command.'

    arguments :args, type: String

    option :format, type: String
    option :out,    type: String

    def process
      formatted = format_parameters

      if out
        file_system.write(out, formatted)
      else
        standard_io.write_output(formatted)
      end

      nil
    end

    private

    def format_arguments_as_text
      return '[]' if args.empty?

      formatted = args.map(&:inspect).join(', ')

      "[#{formatted}]"
    end

    def format_options_as_text(kwargs)
      return '{}' if kwargs.empty?

      formatted =
        kwargs.map { |key, value| "#{key}: #{value.inspect}" }.join(', ')

      "{ #{formatted} }"
    end

    def format_parameters
      case format&.downcase
      when 'json'
        JSON.pretty_generate({ arguments: args, options: options.compact })
      else
        format_parameters_as_text
      end
    end

    def format_parameters_as_text
      buffer = "#{self.class.name} called with "
      kwargs = options.compact

      return buffer << 'no parameters.' if args.empty? && kwargs.empty?

      buffer <<
        "parameters:\n" \
        "\n  Arguments: #{format_arguments_as_text}" \
        "\n  Options:   #{format_options_as_text(kwargs)}" \
        "\n"

      buffer.freeze
    end
  end
end
