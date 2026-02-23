# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'cuprum/cli/rspec/deferred/ci'

module Cuprum::Cli::RSpec::Deferred::Ci
  # Deferred examples for testing CI reports.
  module ReportExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_examples 'should define report subclasses' do
      describe '.define' do
        let(:properties) { super().merge(custom_property: 'custom value') }
        let(:symbols)    { %i[custom_property] }
        let(:block) do
          lambda do
            private def item_name = 'trial'
          end
        end
        let(:subclass) { described_class.define(*symbols, &block) }
        let(:expected_members) do
          described_class.members.concat(symbols)
        end

        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:define)
            .with_unlimited_arguments
            .and_a_block
        end

        it { expect(subclass).to be_a(Class).and be < Data }

        it { expect(subclass.members).to be == expected_members }

        describe 'with a report subclass' do
          let(:described_class) { super().define(*symbols, &block) }
          let(:empty_properties) do
            {
              custom_property: nil,
              duration:        0,
              total_count:     0
            }
          end
          let(:other_properties) do
            {
              custom_property: 'Other Value',
              duration:        5.0,
              error_count:     5,
              failure_count:   15,
              label:           'Other Report',
              pending_count:   25,
              success_count:   35,
              total_count:     75
            }
          end

          include_deferred 'should implement the CI report interface',
            item_name: 'trials'
        end
      end
    end

    deferred_examples 'should implement the CI report interface' \
    do |item_name: 'item'|
      describe '#duration' do
        include_examples 'should define reader',
          :duration,
          -> { properties[:duration] }
      end

      describe '#error_count' do
        include_examples 'should define reader', :error_count, 0

        context 'when initialized with error_count: value' do
          let(:properties) { super().merge(error_count: 10) }

          it { expect(subject.error_count).to be == properties[:error_count] }
        end
      end

      describe '#errored?' do
        include_examples 'should define predicate', :errored?, false

        context 'when initialized with error_count: value' do
          let(:properties) { super().merge(error_count: 10) }

          it { expect(subject.errored?).to be true }
        end
      end

      describe '#failure?' do
        include_examples 'should define predicate', :failure?, false

        context 'when initialized with failure_count: value' do
          let(:properties) { super().merge(failure_count: 20) }

          it { expect(subject.failure?).to be true }
        end
      end

      describe '#failure_count' do
        include_examples 'should define reader', :failure_count, 0

        context 'when initialized with failure_count: value' do
          let(:properties) { super().merge(failure_count: 20) }

          it 'should return the failure count' do
            expect(subject.failure_count).to be == properties[:failure_count]
          end
        end
      end

      describe '#label' do
        include_examples 'should define reader', :label, nil

        context 'when initialized with label: value' do
          let(:properties) { super().merge(label: 'Custom Integration') }

          it { expect(subject.label).to be == properties[:label] }
        end
      end

      describe '#merge' do
        it 'should define the method' do
          expect(subject)
            .to respond_to(:merge)
            .with(1).argument
            .and_keywords(:with_label)
        end

        describe 'with nil' do
          let(:error_message) do
            message = tools.assertions.error_message_for(
              'instance_of',
              as:       'report',
              expected: described_class
            )

            /#{message}/
          end

          it 'should raise an exception' do
            expect { subject.merge(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) do
            message = tools.assertions.error_message_for(
              'instance_of',
              as:       'report',
              expected: described_class
            )

            /#{message}/
          end

          it 'should raise an exception' do
            expect { subject.merge(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty report' do
          let(:empty_properties) do
            next super() if defined?(super())

            {
              duration:    0,
              total_count: 0
            }
          end
          let(:other_report) do
            described_class.new(**empty_properties)
          end
          let(:merged) { subject.merge(other_report) }
          let(:expected) do
            {
              duration:      subject.duration,
              error_count:   subject.error_count,
              failure_count: subject.failure_count,
              label:         subject.label,
              pending_count: subject.pending_count,
              success_count: subject.success_count,
              total_count:   subject.total_count
            }
          end

          it { expect(merged).to be_a described_class }

          it { expect(merged).to have_attributes(**expected) }

          describe 'with label: value' do
            let(:with_label) { 'Merged Report' }
            let(:merged)     { subject.merge(other_report, with_label:) }

            it { expect(merged.label).to be == with_label }
          end

          context 'when initialized with label: value' do
            let(:properties) { super().merge(label: 'Custom Integration') }

            it { expect(merged.label).to be == subject.label }

            describe 'with label: value' do
              let(:with_label) { 'Merged Report' }
              let(:merged)     { subject.merge(other_report, with_label:) }

              it { expect(merged.label).to be == with_label }
            end
          end

          context 'when initialized with multiple counts' do
            let(:properties) do
              super().merge(
                error_count:   10,
                failure_count: 20,
                pending_count: 30
              )
            end

            it { expect(merged).to have_attributes(**expected) }
          end
        end

        describe 'with a non-empty report' do
          let(:other_properties) do
            next super() if defined?(super())

            {
              duration:      5.0,
              error_count:   5,
              failure_count: 15,
              label:         'Other Report',
              pending_count: 25,
              success_count: 35,
              total_count:   75
            }
          end
          let(:other_report) do
            described_class.new(**other_properties)
          end
          let(:merged) { subject.merge(other_report) }
          let(:expected) do
            {
              duration:      subject.duration      + other_report.duration,
              error_count:   subject.error_count   + other_report.error_count,
              failure_count: subject.failure_count + other_report.failure_count,
              label:         other_report.label,
              pending_count: subject.pending_count + other_report.pending_count,
              success_count: subject.success_count + other_report.success_count,
              total_count:   subject.total_count   + other_report.total_count
            }
          end

          it { expect(merged).to be_a described_class }

          it { expect(merged).to have_attributes(**expected) }

          describe 'with label: value' do
            let(:with_label) { 'Merged Report' }
            let(:merged)     { subject.merge(other_report, with_label:) }

            it { expect(merged.label).to be == with_label }
          end

          context 'when initialized with label: value' do
            let(:properties)     { super().merge(label: 'Custom Integration') }
            let(:expected_label) { "#{subject.label} + #{other_report.label}" }

            it { expect(merged.label).to be == expected_label }

            describe 'with label: value' do
              let(:with_label) { 'Merged Report' }
              let(:merged)     { subject.merge(other_report, with_label:) }

              it { expect(merged.label).to be == with_label }
            end
          end

          context 'when initialized with multiple counts' do
            let(:properties) do
              super().merge(
                error_count:   10,
                failure_count: 20,
                pending_count: 30
              )
            end

            it { expect(merged).to have_attributes(**expected) }
          end
        end
      end

      describe '#pending?' do
        include_examples 'should define predicate', :pending?, false

        context 'when initialized with pending_count: value' do
          let(:properties) { super().merge(pending_count: 30) }

          it { expect(subject.pending?).to be true }
        end
      end

      describe '#pending_count' do
        include_examples 'should define reader', :pending_count, 0

        context 'when initialized with pending_count: value' do
          let(:properties) { super().merge(pending_count: 30) }

          it 'should reutrn the pending count' do
            expect(subject.pending_count).to be == properties[:pending_count]
          end
        end
      end

      describe '#success?' do
        include_examples 'should define predicate', :success?, true

        context 'when initialized with error_count: value' do
          let(:properties) { super().merge(error_count: 10) }

          it { expect(subject.success?).to be false }
        end

        context 'when initialized with failure_count: value' do
          let(:properties) { super().merge(failure_count: 20) }

          it { expect(subject.success?).to be false }
        end

        context 'when initialized with pending_count: value' do
          let(:properties) { super().merge(pending_count: 30) }

          it { expect(subject.success?).to be true }
        end
      end

      describe '#success_count' do
        include_examples 'should define reader',
          :success_count,
          -> { properties[:total_count] }

        context 'when initialized with failure_count: value' do
          let(:properties) { super().merge(failure_count: 20) }
          let(:expected) do
            properties[:total_count] - properties[:failure_count]
          end

          it { expect(subject.success_count).to be == expected }
        end

        context 'when initialized with pending_count: value' do
          let(:properties) { super().merge(pending_count: 20) }
          let(:expected) do
            properties[:total_count] - properties[:pending_count]
          end

          it { expect(subject.success_count).to be == expected }
        end

        context 'when initialized with multiple counts' do
          let(:properties) do
            super().merge(failure_count: 10, pending_count: 20)
          end
          let(:expected) do
            properties[:total_count] - (
              properties[:pending_count] + properties[:failure_count]
            )
          end

          it { expect(subject.success_count).to be == expected }
        end

        context 'when initialized with success_count: value' do
          let(:properties) { super().merge(success_count: 25) }

          it 'should return the success count'  do
            expect(subject.success_count).to be == properties[:success_count]
          end

          context 'when initialized with multiple counts' do
            let(:properties) do
              super().merge(failure_count: 10, pending_count: 20)
            end

            it 'should return the success count'  do
              expect(subject.success_count).to be == properties[:success_count]
            end
          end
        end
      end

      describe '#summary' do
        let(:item_label) { tools.str.pluralize(item_name) }
        let(:expected) do
          "#{properties[:total_count]} #{item_label}, " \
            "#{properties.fetch(:failure_count, 0)} failures"
        end

        it { expect(subject).to respond_to(:summary).with(0).arguments }

        it { expect(subject.summary).to be == expected }

        context 'when initialized with error_count: value' do
          let(:properties) { super().merge(error_count: 10) }
          let(:expected)   { "#{super()}, #{properties[:error_count]} errors" }

          it { expect(subject.summary).to be == expected }
        end

        context 'when initialized with failure_count: value' do
          let(:properties) { super().merge(failure_count: 20) }

          it { expect(subject.summary).to be == expected }
        end

        context 'when initialized with pending_count: value' do
          let(:properties) { super().merge(pending_count: 30) }
          let(:expected) do
            "#{super()}, #{properties[:pending_count]} pending"
          end

          it { expect(subject.summary).to be == expected }
        end

        context 'when initialized with multiple counts' do
          let(:properties) do
            super().merge(error_count: 10, failure_count: 20, pending_count: 30)
          end
          let(:expected) do
            "#{super()}, #{properties[:pending_count]} pending, " \
              "#{properties[:error_count]} errors"
          end

          it { expect(subject.summary).to be == expected }
        end
      end

      describe '#total_count' do
        include_examples 'should define reader',
          :total_count,
          -> { properties[:total_count] }
      end
    end
  end
end
