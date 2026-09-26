# frozen_string_literal: true

require 'cuprum/cli/files/templates'

RSpec.describe Cuprum::Cli::Files::Templates do
  describe '.resolve' do
    it { expect(described_class).to respond_to(:resolve).with(1).argument }

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'template')
      end

      it 'should raise an exception' do
        expect { described_class.resolve(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        'template must be a Template or file path'
      end

      it 'should raise an exception' do
        expect { described_class.resolve(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'template')
      end

      it 'should raise an exception' do
        expect { described_class.resolve('') }
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
        expect(described_class.resolve(file_path))
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
        expect(described_class.resolve(raw_template))
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

      it { expect(described_class.resolve(template)).to be template }
    end
  end
end
