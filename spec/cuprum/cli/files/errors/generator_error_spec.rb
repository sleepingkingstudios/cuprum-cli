# frozen_string_literal: true

require 'cuprum/cli/files/errors/generator_error'

RSpec.describe Cuprum::Cli::Files::Errors::GeneratorError do
  subject(:error) { described_class.new(message:, **constructor_options) }

  let(:message)             { 'Something went wrong' }
  let(:constructor_options) { {} }

  describe '::TYPE' do
    include_examples 'should define immutable constant',
      :TYPE,
      'cuprum.cli.files.errors.generator_error'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:details, :file_path, :message, :options)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {},
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }

    context 'when initialized with details: value' do
      let(:details)             { 'should have taken a left turn somewhere...' }
      let(:constructor_options) { super().merge(details:) }
      let(:expected) do
        super().merge('data' => { 'details' => details })
      end

      it { expect(error.as_json).to be == expected }
    end

    context 'when initialized with file_path: value' do
      let(:file_path)           { 'lib/path/to/file.rb' }
      let(:constructor_options) { super().merge(file_path:) }
      let(:expected) do
        super().merge('data' => { 'file_path' => file_path })
      end

      it { expect(error.as_json).to be == expected }
    end

    context 'when initialized with options: value' do
      let(:options)             { { option: 'value' } }
      let(:constructor_options) { super().merge(options:) }
      let(:expected) do
        options = { 'option' => 'value' }

        super().merge('data' => { 'options' => options })
      end

      it { expect(error.as_json).to be == expected }
    end
  end

  describe '#details' do
    include_examples 'should define reader', :details, nil

    context 'when initialized with details: value' do
      let(:details)             { 'should have taken a left turn somewhere...' }
      let(:constructor_options) { super().merge(details:) }

      it { expect(error.details).to be == details }
    end
  end

  describe '#file_path' do
    include_examples 'should define reader', :file_path, nil

    context 'when initialized with file_path: value' do
      let(:file_path)           { 'lib/path/to/file.rb' }
      let(:constructor_options) { super().merge(file_path:) }

      it { expect(error.file_path).to be == file_path }
    end
  end

  describe '#message' do
    include_examples 'should define reader', :message, -> { message }
  end

  describe '#options' do
    include_examples 'should define reader', :options, {}

    context 'when initialized with options: value' do
      let(:options)             { { option: 'value' } }
      let(:constructor_options) { super().merge(options:) }

      it { expect(error.options).to be == options }
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
