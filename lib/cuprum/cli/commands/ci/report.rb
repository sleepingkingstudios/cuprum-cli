# frozen_string_literal: true

require 'cuprum/cli/commands/ci'

module Cuprum::Cli::Commands::Ci
  Report = Data.define(
    :label,
    :duration,
    :error_count,
    :failure_count,
    :pending_count,
    :success_count,
    :total_count
  )

  # Data class for recording the results of a CI command.
  class Report
    # Instance methods included in Report and subclasses.
    module Methods
      # Class methods extended onto Report and subclasses.
      module ClassMethods
        # Defines a Report subclass.
        #
        # @param symbols [Array<Symbol>] additional members to define for the
        #   subclass.
        #
        # @yield additional methods to define for the subclass.
        def define(*symbols, &block)
          Data.define(*members, *symbols) do
            include Report::Methods

            class_exec(&block) if block_given?
          end
        end
      end

      class << self
        private

        def included(other)
          super

          other.singleton_class.prepend(ClassMethods)
        end
      end

      # @param duration [Integer, Float] the duration of the CI step, in
      #   seconds.
      # @param error_count [Integer] the number of static errors reported by the
      #   step.
      # @param failure_count [Integer] the number of failures reported by the
      #   step.
      # @param label [String] a human-readable representation of the step.
      # @param pending_count [Integer] the number of pending items reported by
      #   the step.
      # @param success_count [Integer] the number of successful items reported
      #   by the step. Defaults to calculated from the total minus the pending
      #   and failing items.
      # @param total_count [Integer] the total number of items reported by the
      #   step.
      def initialize( # rubocop:disable Metrics/ParameterLists
        duration:,
        total_count:,
        label:         nil,
        error_count:   0,
        failure_count: 0,
        pending_count: 0,
        success_count: nil,
        **
      )
        success_count ||= total_count - (failure_count + pending_count)

        super
      end

      # @return [true, false] true if the step reported any errors, otherwise
      #   false.
      def errored? = !error_count.zero?

      # @return [true, false] true if the step reported any failing items,
      #   otherwise false.
      def failure? = !failure_count.zero?

      # Combines the given report with the current report.
      #
      # @param other_report [Cuprum::Cli::Commands::Ci::Report] the given
      #   report.
      #
      # @return [Cuprum::Cli::Commands::Ci::Report] the combined report.
      def merge(other_report, with_label: nil) # rubocop:disable Metrics/MethodLength
        tools.assertions.validate_instance_of(
          other_report,
          as:       'report',
          expected: self.class
        )

        with_label ||= [label, other_report.label].compact.join(' + ')
        with_label = nil if with_label.empty?

        self.class.new(
          label: with_label,
          **merge_properties(other_report, except: :label)
        )
      end

      # @return [true, false] true if the step reported any pending items,
      #   otherwise false.
      def pending? = !pending_count.zero?

      # @return [true, false] true if the step did not report any errors or
      #   failing items; otherwise false.
      def success? = !errored? && !failure?

      # Generates a human-readable summary of the report.
      def summary
        summary = "#{total_count} #{tools.string_tools.pluralize(item_name)}"
        summary << ", #{failure_count} failures"
        summary << ", #{pending_count} pending" if pending?
        summary << ", #{error_count} errors"    if errored?

        summary.freeze
      end

      private

      def item_name = 'item'

      def merge_properties(other, except: []) # rubocop:disable Metrics/MethodLength
        excepted = Set.new(Array(except))

        self
          .class
          .members
          .reject { |member_name| excepted.include?(member_name) }
          .to_h do |member_name|
            [
              member_name,
              [
                public_send(member_name),
                other.public_send(member_name)
              ]
                .compact
                .reduce(&:+)
            ]
          end
      end

      def tools = SleepingKingStudios::Tools::Toolbelt.instance
    end

    include Methods
  end
end
