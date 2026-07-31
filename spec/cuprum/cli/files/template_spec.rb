# frozen_string_literal: true

require 'cuprum/cli/files/template'

RSpec.describe Cuprum::Cli::Files::Template do
  subject(:template) { described_class.new(**options) }

  let(:options) { {} }

  describe '.build' do
    it { expect(described_class).to respond_to(:build).with(1).argument }

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'template')
      end

      it 'should raise an exception' do
        expect { described_class.build(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        'template must be a Template or file path'
      end

      it 'should raise an exception' do
        expect { described_class.build(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'template')
      end

      it 'should raise an exception' do
        expect { described_class.build('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a single-line String' do
      let(:file_path) { 'templates/docs.md.erb' }
      let(:expected_attributes) do
        {
          engine:    Cuprum::Cli::Files::Engines::ERB,
          file_path:
        }
      end

      it 'should build a FileTemplate' do
        expect(described_class.build(file_path))
          .to be_a(Cuprum::Cli::Files::Templates::FileTemplate)
          .and have_attributes(**expected_attributes)
      end
    end

    describe 'with a multi-line String' do
      let(:raw_template) do
        <<~MARKDOWN
          # Greetings, Starfighter

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan armada!
        MARKDOWN
      end
      let(:expected_attributes) do
        {
          engine:       nil,
          raw_template:
        }
      end

      it 'should build a StringTemplate' do
        expect(described_class.build(raw_template))
          .to be_a(Cuprum::Cli::Files::Templates::StringTemplate)
          .and have_attributes(**expected_attributes)
      end
    end

    describe 'with a Template instance' do
      let(:raw_template) do
        <<~MARKDOWN
          # Greetings, Starfighter

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan armada!
        MARKDOWN
      end
      let(:template) do
        Cuprum::Cli::Files::Templates::StringTemplate.build(raw_template)
      end

      it { expect(described_class.build(template)).to be template }
    end
  end

  describe '.members' do
    let(:expected) { %i[engine] }

    it { expect(described_class.members).to be == expected }
  end

  describe '#call' do
    let(:expected_error) do
      Cuprum::Errors::CommandNotImplemented.new(command: template)
    end

    it { expect(template).to respond_to(:call).with(0).arguments }

    it 'should return a failing result' do
      expect(template.call)
        .to be_a_failing_result
        .with_error(expected_error)
    end
  end

  describe '#engine' do
    include_examples 'should define reader', :engine, nil

    context 'when initialized with engine: value' do
      let(:engine)  { Cuprum::Cli::Files::Engines::ERB }
      let(:options) { super().merge(engine:) }

      it { expect(template.engine).to be engine }
    end
  end
end
