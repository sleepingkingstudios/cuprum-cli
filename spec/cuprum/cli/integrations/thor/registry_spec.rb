# frozen_string_literal: true

require 'cuprum/cli/integrations/thor/registry'
require 'cuprum/cli/rspec/deferred/registry_examples'

RSpec.describe Cuprum::Cli::Integrations::Thor::Registry do
  include Cuprum::Cli::RSpec::Deferred::RegistryExamples

  subject(:registry) { described_class.new }

  include_deferred 'should implement the Registry interface'

  describe '#register' do
    deferred_examples 'should configure the command' do
      context 'when the command is registered' do
        let(:expected_arguments) do
          config.fetch(:arguments, [])
        end
        let(:expected_full_name) do
          config.fetch(:full_name, command.full_name)
        end
        let(:expected_options) do
          config.fetch(:options, {})
        end

        before(:example) { registry.register(command, **config) }

        it { expect(registered).to be_a(Class).and(be < command) }

        it 'should configure the command argument values' do
          expect(registered.argument_values).to be == expected_arguments
        end

        it 'should configure the command full name' do
          expect(registered.full_name).to be == expected_full_name
        end

        it 'should configure the command option values' do
          expect(registered.option_values).to be == expected_options
        end
      end
    end

    let(:command) { Spec::CustomCommand }
    let(:config)  { {} }
    let(:builder_class) do
      Cuprum::Cli::Integrations::Thor::Task::Builder
    end
    let(:builder)    { @builder } # rubocop:disable RSpec/InstanceVariable
    let(:registered) { builder.command_class }

    example_class 'Spec::CustomCommand', Cuprum::Cli::Command do |klass|
      klass.description 'A custom command.'
    end

    before(:example) do
      allow(builder_class)
        .to receive(:new)
        .and_wrap_original do |original, command|
          @builder = original.call(command).tap do |builder|
            allow(builder).to receive(:build)
          end
        end
    end

    it 'should build the Thor command' do
      registry.register(command)

      expect(builder)
        .to have_received(:build)
        .with(full_name: command.full_name)
    end

    it 'should generate the command' do
      registry.register(command)

      expect(builder.command_class).to be command
    end

    describe 'with arguments: value' do
      let(:arguments)  { %w[ichi ni san] }
      let(:config)     { super().merge(arguments:) }

      include_deferred 'should configure the command'
    end

    describe 'with full_name: value' do
      let(:full_name) { 'spec:custom:command' }
      let(:config)    { super().merge(full_name:) }

      it 'should build the Thor command' do
        registry.register(command, full_name:)

        expect(builder).to have_received(:build).with(full_name:)
      end

      include_deferred 'should configure the command'
    end

    describe 'with options: value' do
      let(:options) { { option: 'value', other: 'other' } }
      let(:config)  { super().merge(options:) }

      include_deferred 'should configure the command'
    end
  end
end
