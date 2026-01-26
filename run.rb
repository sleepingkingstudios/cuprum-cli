# frozen_string_literal: true

require 'open3'
require 'stringio'

require 'byebug'
require 'plumbum'

require 'cuprum/cli'

module Cuprum::Cli
  module Options
    module Quiet
      DESCRIPTION = 'Silences non-essential console outputs.'.freeze
      private_constant :DESCRIPTION

      class << self
        def included(other)
          super

          other.option   :quiet,
            type:        :boolean,
            aliases:     :q,
            default:     false,
            description: DESCRIPTION
        end
      end

      def say(message, quiet: false, **)
        return if options.fetch(:quiet, false) && !quiet

        super
      end
    end

    module Verbose
      DESCRIPTION = 'Enables optional console outputs.'.freeze
      private_constant :DESCRIPTION

      class << self
        def included(other)
          super

          other.option   :verbose,
            type:        :boolean,
            aliases:     :v,
            default:     false,
            description: DESCRIPTION
        end
      end

      def say(message, verbose: false, **)
        return if verbose && !(options.fetch(:verbose, false))

        super
      end
    end
  end

  class SpecCommand < Cuprum::Cli::Command
    # dependency :file_system
    dependency :standard_io
    dependency :system_command

    include Dependencies::StandardIo::Helpers
    include Options::Quiet
    include Options::Verbose

    option :color, type: :boolean, default: true
    option :format

    class << self
      def description
        'Runs an RSpec command'
      end

      def full_description
        'Runs an RSpec command'
      end
    end

    private

    def run_command
      arguments = [color? ? :'--force_color' : :'--no_color']
      options   = { format: }

      system_command.capture('rspec', arguments:, options:)
    end

    def process
      result = run_command
      output = result.value&.output
      error  = result.value&.error

      say(output) if output && !output.empty?
      warn(error) if error  && !error.empty?

      result
    end
  end
end

# captures = {
#   'rspec' => -> { ['Greetings, starfighter!', 'Oh no', 1] }
# }
# mock_command = Cuprum::Cli::Dependencies::SystemCommand::Mock.new(captures:)
# mock_io = Cuprum::Cli::Dependencies::StandardIo::Mock.new
command = Cuprum::Cli::SpecCommand.new#(system_command: mock_command)
result  = command.call(format: :doc, quiet: false)

# byebug
self
