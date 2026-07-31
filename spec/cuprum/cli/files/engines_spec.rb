# frozen_string_literal: true

require 'cuprum/cli/files/engines'

RSpec.describe Cuprum::Cli::Files::Engines do
  describe '::ERB' do
    include_examples 'should define immutable constant',
      :ERB,
      'cuprum.cli.files.engines.erb'
  end

  describe '.fetch' do
    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:fetch)
        .with(1..2).arguments
        .and_a_block
    end

    describe 'with an undefined engine' do
      let(:engine)        { 'jinja2' }
      let(:error_message) { "key not found: #{engine.inspect}" }

      it 'should raise an exception' do
        expect { described_class.fetch(engine) }
          .to raise_error(KeyError, error_message)
      end

      describe 'with a default block' do
        let(:default)  { Class.new(Cuprum::Command) }
        let(:block)    { ->(*) { default } }

        it 'should call the block with the requested engine' do
          expect { |block| described_class.fetch(engine, &block) }
            .to yield_with_args(engine)
        end

        it { expect(described_class.fetch(engine, &block)).to be default }
      end

      describe 'with a default value' do
        let(:default) { Class.new(Cuprum::Command) }

        it { expect(described_class.fetch(engine, default)).to be default }
      end
    end

    describe 'with a defined engine' do
      let(:engine)  { described_class::ERB }
      let(:command) { described_class::RenderErb }

      it { expect(described_class.fetch(engine)).to be command }

      describe 'with a default block' do
        let(:block) { -> {} }

        it 'should not call the block' do
          expect { |block| described_class.fetch(engine, &block) }
            .not_to yield_control
        end

        it { expect(described_class.fetch(engine, &block)).to be command }
      end

      describe 'with a default value' do
        let(:default) { Class.new(Cuprum::Command) }

        it { expect(described_class.fetch(engine, default)).to be command }
      end
    end

    context 'when additional engines are registered' do
      let(:liquid_command) { Class.new(Cuprum::Command) }

      before(:example) do
        described_class.register('liquid', liquid_command)
      end

      after(:example) do
        described_class.instance_variable_set(:@engines, nil)
      end

      describe 'with an undefined engine' do
        let(:engine)        { 'jinja2' }
        let(:error_message) { "key not found: #{engine.inspect}" }

        it 'should raise an exception' do
          expect { described_class.fetch(engine) }
            .to raise_error(KeyError, error_message)
        end
      end

      describe 'with a defined engine' do
        let(:engine)  { described_class::ERB }
        let(:command) { described_class::RenderErb }

        it { expect(described_class.fetch(engine)).to be command }
      end

      describe 'with an added engine' do
        let(:engine)  { 'liquid' }
        let(:command) { liquid_command }

        it { expect(described_class.fetch(engine)).to be command }
      end
    end
  end

  describe '.register' do
    let(:liquid_command) { Class.new(Cuprum::Command) }

    after(:example) do
      described_class.instance_variable_set(:@engines, nil)
    end

    it 'should define the class method' do
      expect(described_class).to respond_to(:register).with(2).arguments
    end

    it 'should register the engine' do
      described_class.register('liquid', liquid_command)

      expect(described_class.fetch('liquid')).to be liquid_command
    end
  end
end
