# frozen_string_literal: true

require 'cuprum/cli/integrations/thor/registry'
require 'cuprum/cli/rspec/deferred/registry_examples'

RSpec.describe Cuprum::Cli::Integrations::Thor::Registry do
  include Cuprum::Cli::RSpec::Deferred::RegistryExamples

  subject(:registry) { described_class.new }

  include_deferred 'should implement the Registry interface'

  describe '#register' do
    let(:command) { Spec::CustomCommand }
    let(:builder_class) do
      Cuprum::Cli::Integrations::Thor::Task::Builder
    end
    let(:builder) { @builder } # rubocop:disable RSpec/InstanceVariable

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

      expect(builder).to have_received(:build).with(full_name: nil)
    end

    it 'should generate the command' do
      registry.register(command)

      expect(builder.command_class).to be command
    end

    describe 'with arguments: value' do
      let(:arguments)  { %w[ichi ni san] }
      let(:registered) { builder.command_class }

      it 'should configure the command', :aggregate_failures do
        registry.register(command, arguments:)

        expect(registered).to be_a(Class).and(be < command)
        expect(registered.argument_values).to be == arguments
        expect(registered.option_values).to be == {}
      end
    end

    describe 'with name: value' do
      let(:name) { 'spec:custom:command' }

      it 'should build the Thor command' do
        registry.register(command, name:)

        expect(builder).to have_received(:build).with(full_name: name)
      end
    end

    describe 'with options: value' do
      let(:options)    { { option: 'value', other: 'other' } }
      let(:registered) { builder.command_class }

      it 'should configure the command', :aggregate_failures do
        registry.register(command, options:)

        expect(registered).to be_a(Class).and(be < command)
        expect(registered.argument_values).to be == []
        expect(registered.option_values).to be == options
      end
    end
  end
end
