# frozen_string_literal: true

require 'json'

require 'byebug'
require 'sleeping_king_studios/tools/toolbox/mixin'

require 'cuprum/cli'

module Cuprum::Cli
  module Commands
    module Ci
      class RSpecCommand < Cuprum::Cli::Command
        dependency :file_system
        dependency :standard_io
        dependency :system_command

        include Dependencies::StandardIo::Helpers
        include Options::Quiet
        include Options::Verbose

        arguments :file_patterns

        option :color, type: :boolean, default: true
        option :format

        description 'Runs an RSpec command.'

        full_name 'ci:rspec'

        private

        def command_arguments(file_path)
          [
            *file_patterns,
            color? ? '--force_color' : '--no_color',
            '--format=json',
            "--out=#{file_path}"
          ]
        end

        def command_options
          { format: }
        end

        def generate_report(data)
          Report.new(
            label: 'ci:rspec',
            duration: data['duration'],
            error_count: data['errors_outside_of_examples_count'],
            failure_count: data['failure_count'],
            pending_count: data['pending_count'],
            total_count: data['example_count']
          )
        end

        def process
          json = file_system.with_tempfile do |tempfile|
            run_command(tempfile)

            json =
              file_system
              .read_file(tempfile)
              .then { |raw| JSON.parse(raw) }
              .then { |hsh| hsh['summary'] }
          end

          puts JSON.pretty_generate(json)

          generate_report(json)
        end

        def run_command(tempfile)
          arguments = command_arguments(tempfile.path)
          options   = command_options
          result    = system_command.capture('rspec', arguments:, options:)

          output = result.value&.output
          error  = result.value&.error

          say(output) if output && !output.empty?
          warn(error) if error  && !error.empty?
        end
      end
    end
  end
end

# captures = {
#   'rspec' => -> { ['Greetings, starfighter!', 'Oh no', 1] }
# }
# mock_command = Cuprum::Cli::Dependencies::SystemCommand::Mock.new(captures:)
# mock_io = Cuprum::Cli::Dependencies::StandardIo::Mock.new
# mock_fs = Cuprum::Cli::Dependencies::FileSystem::Mock.new
command = Cuprum::Cli::Commands::Ci::RSpecCommand.new
result  = command.call(format: :progress, quiet: false)

puts result.value.summary

# byebug
self
