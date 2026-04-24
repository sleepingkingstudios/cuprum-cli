# frozen_string_literal: true

require 'cuprum/cli/command'
require 'cuprum/cli/commands/file'
require 'cuprum/cli/commands/file/render_erb'
require 'cuprum/cli/commands/file/resolve_template'

module Cuprum::Cli::Commands::File
  # Command for generating a templated file or files.
  class NewCommand < Cuprum::Cli::Command
    dependency :file_system
    dependency :standard_io

    include Cuprum::Cli::Options::Quiet
    include Cuprum::Cli::Options::Verbose

    argument :file_path, type: String, required: true

    option :directories,  type: :boolean, default: true
    option :dry_run,      type: :boolean, default: false
    option :parent_class, type: String
    option :templates,
      type:    Array,
      default: Cuprum::Cli::Commands::File::Templates::DEFAULT_TEMPLATES
    option :extra_flags,
      type:     :boolean,
      variadic: true

    description 'Generates a new templated file or files.'

    private

    def excluded_tags
      excluded = []

      extra_flags.each do |flag, value|
        excluded << flag if value == false
      end

      excluded
    end

    def generate_file(file_path:, parameters:, template_path:) # rubocop:disable Metrics/MethodLength
      file_path = resolve_file_path(file_path, **parameters)
      command   = GenerateFile.new(
        file_system:,
        standard_io:,
        directories: directories?,
        dry_run:     dry_run?,
        quiet:       quiet?,
        verbose:     verbose?
      )

      parameters = parameters.merge(parent_class:)

      step { command.call(file_path:, parameters:, template_path:) }

      file_path
    end

    def process
      templates, parameters = step { resolve_template }

      templates.map do |template|
        file_path     = template.fetch(:file_path, self.file_path)
        template_path = template.fetch(:template)

        step { generate_file(file_path:, parameters:, template_path:) }
      end
    end

    def resolve_file_path(file_path, **params)
      params = tools.hash_tools.convert_keys_to_symbols(params)

      format(file_path, params)
    end

    def resolve_template
      command = Cuprum::Cli::Commands::File::ResolveTemplate.new(templates:)

      command.call(file_path, except: excluded_tags)
    end

    def tools = @tools ||= SleepingKingStudios::Tools::Toolbelt.instance
  end
end
