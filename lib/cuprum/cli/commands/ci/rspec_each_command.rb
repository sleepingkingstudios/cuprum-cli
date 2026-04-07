# frozen_string_literal: true

require 'cuprum/cli/commands/ci'
require 'cuprum/cli/commands/ci/rspec_command'

module Cuprum::Cli::Commands::Ci
  # Command for running each RSpec file in its own process.
  class RSpecEachCommand < Cuprum::Cli::Command # rubocop:disable Metrics/ClassLength
    dependency :file_system
    dependency :standard_io

    include Cuprum::Cli::Dependencies::StandardIo::Helpers
    include Cuprum::Cli::Options::Quiet

    arguments :file_patterns

    option :color, type: :boolean, default: true
    option :env,   type: :hash,    default: {}
    option :gemfile

    description 'Runs each RSpec file in an isolated process.'

    full_name 'ci:rspec_each'

    private

    attr_reader :errored_files

    attr_reader :failing_files

    attr_reader :pending_files

    attr_reader :report

    def aggregate_file_results(filename:, result:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      merge_report(result) if result.success?

      if result.value&.errored? || result.failure?
        errored_files << filename
      elsif result.value&.failure?
        failing_files << filename
      elsif result.value&.pending?
        pending_files << filename
      end
    end

    def color(text, color)
      return text unless color?

      standard_io.color(text, color)
    end

    def configured_file_patterns
      patterns = arguments.fetch(:file_patterns, [])

      return patterns unless patterns.empty?

      ['**{,/*/**}/*_spec.rb']
    end

    def format_status(result)
      if result.failure? || result.value.errored?
        color('Errored', 'red')
      elsif result.value.failure?
        color('Failing', 'red')
      elsif result.value.pending?
        color('Pending', 'yellow')
      else
        color('Passing', 'green')
      end
    end

    def matching_files
      return @matching_files if @matching_files

      all_files = Set.new

      configured_file_patterns.each do |pattern|
        file_system.each_file(pattern) { |filename| all_files << filename }
      end

      @matching_files = all_files.sort
    end

    def merge_report(result) = @report = report.merge(result.value)

    def process
      reset_report

      say "Running #{matching_files.count} spec files...\n"
      say "\n" unless matching_files.none?

      matching_files.each { |filename| run_file(filename) }

      say_pending
      say_failures
      say_errored
      say_summary

      report.with(label: 'ci:rspec_each')
    end

    def reset_report
      @errored_files = []
      @failing_files = []
      @pending_files = []
      @report        = Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
        duration:    0.0,
        total_count: 0
      )
    end

    def run_file(filename)
      command  =
        Cuprum::Cli::Commands::Ci::RSpecCommand.new(file_system:, standard_io:)
      result   = command.call(filename, env:, gemfile:, quiet: true)
      filename = trim_filename(filename)

      say "#{format_status(result)} #{filename}"

      aggregate_file_results(filename:, result:)

      result
    end

    def say_errored
      return if errored_files.empty?

      say "\nErrored:\n\n"

      errored_files.each do |filename|
        say color("  #{filename}", 'red')
      end
    end

    def say_failures
      return if failing_files.empty?

      say "\nFailures:\n\n"

      failing_files.each do |filename|
        say color("  #{filename}", 'red')
      end
    end

    def say_pending
      return if pending_files.empty?

      say "\nPending:\n\n"

      pending_files.each do |filename|
        say color("  #{filename}", 'yellow')
      end
    end

    def say_summary # rubocop:disable Metrics/AbcSize
      say "\nFinished in #{report.duration.round(2)} seconds"

      summary_color =
        if report.errored? || report.failure? || errored_files.any?
          'red'
        elsif report.pending? || report.total_count.zero?
          'yellow'
        else
          'green'
        end

      say color(report.summary, summary_color)
    end

    def trim_filename(filename)
      filename.sub(%r{\A#{file_system.root_path}/?}, '')
    end
  end
end
