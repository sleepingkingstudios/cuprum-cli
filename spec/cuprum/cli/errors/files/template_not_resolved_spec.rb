# frozen_string_literal: true

require 'cuprum/cli/errors/files/template_not_resolved'

RSpec.describe Cuprum::Cli::Errors::Files::TemplateNotResolved do
  subject(:error) { described_class.new(file_path:, **options) }

  let(:file_path) { 'path/to/file.txt' }
  let(:options)   { {} }

  describe '::TYPE' do
    include_examples 'should define immutable constant',
      :TYPE,
      'cuprum.cli.errors.files.template_not_resolved'
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
        'data'    => {
          'file_path' => file_path
        },
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }

    context 'when initialized with details: value' do
      let(:details) { 'should have taken a left turn somewhere...' }
      let(:options) { super().merge(details:) }
      let(:expected) do
        {
          'data'    => {
            'details'   => details,
            'file_path' => file_path
          },
          'message' => error.message,
          'type'    => error.type
        }
      end

      it { expect(error.as_json).to be == expected }
    end

    context 'when initialized with options: value' do
      let(:options) { super().merge(options: { doc: true, spec: false }) }
      let(:expected) do
        {
          'data'    => {
            'file_path' => file_path,
            'options'   => { 'doc' => true, 'spec' => false }
          },
          'message' => error.message,
          'type'    => error.type
        }
      end

      it { expect(error.as_json).to be == expected }
    end
  end

  describe '#details' do
    include_examples 'should define reader', :details, nil

    context 'when initialized with details: value' do
      let(:details) { 'should have taken a left turn somewhere...' }
      let(:options) { super().merge(details:) }

      it { expect(error.details).to be == details }
    end
  end

  describe '#file_path' do
    include_examples 'should define reader', :file_path, -> { file_path }
  end

  describe '#message' do
    let(:expected) do
      "unable to resolve template for file #{file_path}"
    end

    include_examples 'should define reader', :message, -> { expected }

    context 'when initialized with message: value' do
      let(:message)  { 'template not found' }
      let(:options)  { super().merge(message:) }
      let(:expected) { "#{super()} - #{message}" }

      it { expect(error.message).to be == expected }
    end

    context 'when initialized with options: value' do
      let(:options)  { super().merge(options: { doc: true, spec: false }) }
      let(:expected) { "#{super()} with options doc: true, spec: false" }

      it { expect(error.message).to be == expected }
    end
  end

  describe '#options' do
    include_examples 'should define reader', :options, {}

    context 'when initialized with options: value' do
      let(:options) { super().merge(options: { doc: true, spec: false }) }

      it { expect(error.options).to be == options[:options] }
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
