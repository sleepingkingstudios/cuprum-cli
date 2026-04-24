# frozen_string_literal: true

require 'cuprum/command'
require 'plumbum'

require 'cuprum/cli/commands/file'
require 'cuprum/cli/commands/file/render_erb'
require 'cuprum/cli/dependencies'
require 'cuprum/cli/dependencies/file_system'
require 'cuprum/cli/errors/files/missing_template'
require 'cuprum/cli/options'

module Cuprum::Cli::Commands::File
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

    def check_if_file_already_exists(file_path:)
      return unless file_system.file?(file_path)
      return if force?

      error  =
        file_not_writeable_error(file_path:, reason: 'file already exists')

      failure(error)
    end

    def check_if_file_is_directory(file_path:)
      return unless file_system.directory?(file_path)

      error  =
        file_not_writeable_error(file_path:, reason: 'file is a directory')

      failure(error)
    end

    def create_directory(file_path:)
      return unless directories?

      return if dry_run?
      return if file_system.directory?(file_path)

      *dir_names, _ = file_path.split(File::SEPARATOR)

      return if dir_names.empty?

      file_system.create_directory(
        dir_names.join(File::SEPARATOR),
        recursive: true
      )
    end

    def file_not_writeable_error(**)
      Cuprum::Cli::Errors::Files::FileNotWriteable.new(**)
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

      step { create_directory(file_path:) }

      step { write_file(contents:, file_path:) }

      file_path
    end

    def render_template(parameters:, template:, template_path:)
      case File.extname(template_path)
      when '.erb'
        RenderErb.new(template_name: template_path).call(template, **parameters)
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

    def write_file(contents:, file_path:)
      step { check_if_file_is_directory(file_path:) }
      step { check_if_file_already_exists(file_path:) }

      file_system.write_file(file_path, contents) unless dry_run?
    rescue Cuprum::Cli::Dependencies::FileSystem::DirectoryNotFoundError
      error =
        file_not_writeable_error(file_path:, reason: 'directory not found')

      failure(error)
    end
  end
end
