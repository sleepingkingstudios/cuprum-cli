# frozen_string_literal: true

require 'cuprum/command'
require 'plumbum'

require 'cuprum/cli/dependencies'
require 'cuprum/cli/dependencies/file_system'
require 'cuprum/cli/errors/files/missing_template'
require 'cuprum/cli/files'
require 'cuprum/cli/files/render_erb'
require 'cuprum/cli/options'

module Cuprum::Cli::Files
  # Utility command for generating a file from a template.
  class GenerateFile < Cuprum::Command
    include Plumbum::Consumer
    prepend Plumbum::Parameters
    include Cuprum::Cli::Dependencies::StandardIo::Helpers
    extend  Cuprum::Cli::Options::ClassMethods
    include Cuprum::Cli::Options::Quiet
    include Cuprum::Cli::Options::Verbose

    dependency :file_system
    dependency :standard_io

    provider Cuprum::Cli::Dependencies.provider

    option :directories, type: :boolean, default: true
    option :dry_run,     type: :boolean, default: false
    option :force,       type: :boolean, default: false

    # @overload initialize(**options)
    #   @param options [Hash] options for initializing the command.
    def initialize(**)
      super()

      @options = self.class.resolve_options(**)
    end

    private

    attr_reader :options

    def create_file(contents:, file_path:)
      Cuprum::Cli::Files::CreateFile
        .new(
          directories: directories?,
          dry_run:     dry_run?,
          force:       force?,
          file_system:
        )
        .call(contents:, file_path:)
    end

    def load_template(file_path:, template_path:)
      file_system.read_file(template_path)
    rescue Cuprum::Cli::Dependencies::FileSystem::FileNotFoundError
      error = Cuprum::Cli::Errors::Files::MissingTemplate.new(
        message:       "unable to generate file #{file_path}",
        template_path:
      )
      failure(error)
    end

    def process(file_path:, parameters:, template_path:)
      say "Generating file #{file_path}..."

      template = step { load_template(file_path:, template_path:) }
      contents =
        step { render_template(parameters:, template:, template_path:) }

      report_file_contents(contents)

      step { create_file(contents:, file_path:) }

      file_path
    end

    def render_template(parameters:, template:, template_path:)
      case File.extname(template_path)
      when '.erb'
        Cuprum::Cli::Files::RenderErb
          .new(template_name: template_path).call(template, **parameters)
      else
        template
      end
    end

    def report_file_contents(contents)
      say "\n", verbose: true
      say(
        contents
          .each_line
          .map { |line| line == "\n" ? "\n" : "  #{line}" }.join,
        verbose: true
      )
      say "\n", verbose: true
    end
  end
end
