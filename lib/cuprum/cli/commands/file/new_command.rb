# frozen_string_literal: true

require 'cuprum/cli/command'
require 'cuprum/cli/commands/file'
require 'cuprum/cli/commands/file/render_erb'

module Cuprum::Cli::Commands::File
  # Command for generating a templated file or files.
  class NewCommand < Cuprum::Cli::Command
    dependency :file_system
    dependency :standard_io

    include Cuprum::Cli::Options::Quiet
    include Cuprum::Cli::Options::Verbose

    class << self
      # @return [Array<Class>] the default generators configured for the
      #   command.
      def default_generators
        [
          Cuprum::Cli::Files::Generators::RubyGenerator,
          Cuprum::Cli::Files::Generators::RSpecGenerator
        ]
      end
    end

    argument :file_path, type: String, required: true

    option :directories, type: :boolean, default: true
    option :dry_run,     type: :boolean, default: false
    option :generators,  type: :array,   default: default_generators
    option :params,      type: :object,  variadic: true

    description 'Generates a new templated file or files.'

    private

    def build_generator
      generator = generators.reverse_each.find do |generator_class|
        generator_class.match?(file_path, **params)
      end

      if generator
        return generator.new(file_path, **params, **generator_options)
      end

      details = 'no generator matches the file path and options'
      failure(generator_error(details:))
    end

    def generator_error(details: nil)
      message = "unable to generate file #{file_path}"
      message = "#{message} - #{details}" if details

      Cuprum::Cli::Errors::Files::GeneratorError.new(
        details:,
        file_path:,
        message:,
        options:
      )
    end

    def generator_options
      {
        directories: directories?,
        dry_run:     dry_run?,
        file_system:,
        quiet:       quiet?,
        standard_io:,
        verbose:     verbose?
      }
    end

    def process
      generator = step { build_generator }

      generator.call
    end
  end
end
