# frozen_string_literal: true

require 'json'

require 'cuprum/cli/commands/ci'

module Cuprum::Cli::Commands::Ci
  # Command for running an RSpec test suite.
  class RSpecCommand < Cuprum::Cli::Command
    # Data class for recording the results of an RSpec command.
    Report = Cuprum::Cli::Commands::Ci::Report.define do
      private

      def item_name = 'example'
    end

    dependency :file_system
    dependency :standard_io
    dependency :system_command

    include Cuprum::Cli::Dependencies::StandardIo::Helpers
    include Cuprum::Cli::Options::Quiet

    arguments :file_patterns

    option :color,    type: :boolean, default: true
    option :coverage, type: :boolean, default: false
    option :env,      type: :hash,    default: {}
    option :format,   type: :string,  default: 'progress'
    option :gemfile

    description 'Runs an RSpec command.'

    full_name 'ci:rspec'

    private

    def collect_stats
      file_system.with_tempfile do |tempfile|
        yield tempfile

        file_system
          .read_file(tempfile)
          .then { |raw| JSON.parse(raw) }
          .then { |hsh| hsh['summary'] }
      end
    rescue JSON::ParserError => exception
      failure(json_error(exception.message))
    end

    def command_arguments(file_path)
      [
        *file_patterns,
        color? ? '--force-color' : '--no-color',
        '--format=json',
        "--out=#{file_path}"
      ]
    end

    def command_environment
      env = self.env.dup
      env[:coverage]         = false unless coverage?
      env[:bundler_gemfile]  = gemfile if gemfile
      env
    end

    def command_options
      { format: quiet? ? nil : format }
    end

    def generate_report(data)
      Report.new(
        label:         'ci:rspec',
        duration:      data.fetch('duration'),
        error_count:   data.fetch('errors_outside_of_examples_count'),
        failure_count: data.fetch('failure_count'),
        pending_count: data.fetch('pending_count'),
        total_count:   data.fetch('example_count')
      )
    end

    def json_error(message)
      message = "unable to parse JSON results - #{message}"

      Cuprum::Error.new(message:)
    end

    def process
      json = step do
        collect_stats { |tempfile| run_command(tempfile) }
      end

      generate_report(json)
    end

    def run_command(tempfile)
      arguments   = command_arguments(tempfile.path)
      environment = command_environment
      options     = command_options

      system_command.spawn('rspec', arguments:, environment:, options:)
    end
  end
end
