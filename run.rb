# frozen_string_literal: true

require 'open3'
require 'stringio'

require 'byebug'
require 'plumbum'

require 'cuprum/cli'

module Cuprum::Cli
  module Dependencies
    class SystemCommand
      def run; end
    end
  end

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
    # dependency :system_command

    include Options::Quiet
    include Options::Verbose

    argument :file_one, required: true

    argument :file_two

    arguments :file_patterns

    argument :last_file

    option :color,
      type:    :boolean,
      default: true

    option :format,
      type:    :string,
      aliases: :f,
      define_predicate: true

    class << self
      def description
        'Runs an RSpec command'
      end

      def full_description
        'Runs an RSpec command'
      end
    end

    private

    def process
      puts `rspec --force-color`
    end
  end
end

# mock_io = Cuprum::Cli::Dependencies::StandardIo::Mock.new

# outputs = Open3.capture3('bundle exec rspec')

command = Cuprum::Cli::SpecCommand.new
command.call('one.rb', 'two.rb', 'three.rb', 'four.rb', 'five.rb', quiet: false, verbose: false, color: true, format: :json)

byebug
self
