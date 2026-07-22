# frozen_string_literal: true

require 'cuprum/cli/dependencies'

module Cuprum::Cli::Dependencies
  # Utility wrapping the current time and time calculations.
  class Clock
    # @return [Numeric] a monotonically increasing system clock time.
    def get_monotonic_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) # rubocop:disable Naming/AccessorMethodName

    # @return [Time] the current time in the UTC time zone.
    def get_time = Time.now(in: 'Z') # rubocop:disable Naming/AccessorMethodName
    alias current_time get_time
    alias now get_time

    # Measures the time elapsed while the block is run.
    def measure
      start_time = get_monotonic_time

      yield

      get_monotonic_time - start_time
    end
  end
end
