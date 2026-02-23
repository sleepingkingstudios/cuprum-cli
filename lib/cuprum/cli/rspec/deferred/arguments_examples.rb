# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'cuprum/cli/rspec/deferred'

module Cuprum::Cli::RSpec::Deferred
  # Deferred examples for testing command arguments.
  module ArgumentsExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_examples 'should define argument' \
    do |index, argument_name, **argument_options|
      expect_method =
        argument_options
        .fetch(:define_method, argument_options[:type] != :boolean)
      expect_predicate =
        argument_options
        .fetch(:define_predicate, argument_options[:type] == :boolean)

      let(:configured_default) do
        value = argument_options[:default]

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:configured_description) do
        value = argument_options[:description]

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:configured_parameter_name) do
        value = argument_options[:parameter_name]

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:configured_required) do
        value = argument_options[:required] ? true : false

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:configured_type) do
        value = argument_options.fetch(:type, :string)

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:configured_variadic) do
        value = argument_options.fetch(:variadic, false)

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:configured_arguments) do
        value = argument_options.fetch(:arguments) do
          defined?(arguments) ? arguments : {}
        end

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:defined_argument) { described_class.arguments[index] }

      define_method :set_argument do |argument, value|
        arguments = subject.instance_variable_get(:@arguments)

        arguments[argument] = value
      end

      it { expect(described_class.arguments.size).to be >= 1 + index }

      describe '#:argument_name' do
        if expect_method
          let(:reader_name) { argument_name }

          it { expect(subject).to respond_to(reader_name).with(0).arguments }

          context 'when the argument is not initialized' do
            before(:example) do
              set_argument(argument_name, configured_default)
            end

            it 'should return the default value' do
              expect(subject.public_send(reader_name))
                .to be == configured_default
            end
          end

          context 'when the argument is set' do
            let(:value) { 'argument value' }

            before(:example) do
              set_argument(argument_name, value)
            end

            it { expect(subject.public_send(reader_name)).to be == value }
          end
        else
          it { expect(subject).not_to respond_to(argument_name) }
        end
      end

      describe '#:argument_name?' do
        if expect_predicate
          let(:predicate_name) { "#{argument_name}?" }

          it { expect(subject).to respond_to(predicate_name).with(0).arguments }

          context 'when the argument is not initialized' do
            let(:expected) do
              next false if configured_default.nil?
              next false if configured_default == false
              next true  unless configured_default.respond_to?(:empty?)

              !configured_default.empty?
            end

            before(:example) do
              set_argument(argument_name, configured_default)
            end

            it 'should return the default value' do
              expect(subject.public_send(predicate_name)).to be == expected
            end
          end

          context 'when the argument is set to false' do
            before(:example) do
              set_argument(argument_name, false)
            end

            it { expect(subject.public_send(predicate_name)).to be false }
          end

          context 'when the argument is set to true' do
            before(:example) do
              set_argument(argument_name, true)
            end

            it { expect(subject.public_send(predicate_name)).to be true }
          end

          if argument_options[:type] != :boolean
            context 'when the argument is set to an Object' do
              before(:example) do
                set_argument(argument_name, Object.new.freeze)
              end

              it { expect(subject.public_send(predicate_name)).to be true }
            end

            context 'when the argument is set to an empty value' do
              before(:example) do
                set_argument(argument_name, '')
              end

              it { expect(subject.public_send(predicate_name)).to be false }
            end

            context 'when the argument is set to a non-empty value' do
              before(:example) do
                set_argument(argument_name, 'value')
              end

              it { expect(subject.public_send(predicate_name)).to be true }
            end
          end
        else
          it { expect(subject).not_to respond_to(:"#{argument_name}?") }
        end
      end

      describe '#default' do
        it { expect(defined_argument.default).to be == configured_default }
      end

      describe '#description' do
        it 'should return the option description' do
          expect(defined_argument.description).to be == configured_description
        end
      end

      describe '#parameter_name' do
        it 'should return the option parameter name' do
          expect(defined_argument.parameter_name)
            .to be == configured_parameter_name
        end
      end

      describe '#required?' do
        it { expect(defined_argument.required?).to be configured_required }
      end

      describe '#type' do
        it { expect(defined_argument.type).to be configured_type }
      end

      describe '#variadic?' do
        it { expect(defined_argument.variadic?).to be configured_variadic }
      end
    end
  end
end
