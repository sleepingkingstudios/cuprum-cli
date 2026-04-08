# frozen_string_literal: true

require 'cuprum/cli/errors/files/template_error'

RSpec.describe Cuprum::Cli::Errors::Files::TemplateError do
  subject(:error) { described_class.new(message:, **options) }

  let(:message) { 'Something went wrong' }
  let(:options) { {} }

  describe '::TYPE' do
    include_examples 'should define immutable constant',
      :TYPE,
      'cuprum.cli.errors.files.template_error'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:details, :message, :template_name)
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
      let(:details) { 'should have taken a left turn somewhere...' }
      let(:options) { super().merge(details:) }
      let(:expected) do
        {
          'data'    => {
            'details' => error.details
          },
          'message' => error.message,
          'type'    => error.type
        }
      end

      it { expect(error.as_json).to be == expected }
    end

    context 'when initialized with template_name: value' do
      let(:template_name) { 'template.html.erb' }
      let(:options)       { super().merge(template_name:) }
      let(:expected) do
        {
          'data'    => {
            'template_name' => template_name
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

  describe '#message' do
    include_examples 'should define reader', :message, -> { message }
  end

  describe '#template_name' do
    include_examples 'should define reader', :template_name, nil

    context 'when initialized with template_name: value' do
      let(:template_name) { 'template.html.erb' }
      let(:options)       { super().merge(template_name:) }

      it { expect(error.template_name).to be == template_name }
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
