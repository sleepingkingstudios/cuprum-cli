# frozen_string_literal: true

require 'async'
require 'async/semaphore'

require 'cuprum/cli/commands/ci/rspec_each_command'
require 'cuprum/cli/integrations/async/commands'

module Cuprum::Cli::Integrations::Async::Commands
  # Command for running each RSpec file in its own process with parallelism.
  class RSpecEachCommand < Cuprum::Cli::Commands::Ci::RSpecEachCommand
    description 'Runs each RSpec file in an isolated process.'

    full_name 'ci:rspec_each'

    option :max_jobs,
      type:    :integer,
      default: Cuprum::Cli::Integrations::Async.max_concurrent_tasks

    private

    def run_matching_files
      Sync do
        semaphore = ::Async::Semaphore.new(8)

        matching_files.each do |filename|
          semaphore.async { run_file(filename) }
        end
      end
    end
  end
end
