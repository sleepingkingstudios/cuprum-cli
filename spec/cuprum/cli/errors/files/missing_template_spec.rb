# frozen_string_literal: true

require 'cuprum/cli/errors/files/missing_template'

RSpec.describe Cuprum::Cli::Errors::Files::MissingTemplate do
  subject(:error) { described_class.new(template_path:, **options) }

  let(:template_path) { 'path/to/template.txt' }
  let(:options)       { {} }

  describe '::TYPE' do
    include_examples 'should define immutable constant',
      :TYPE,
      'cuprum.cli.errors.files.missing_template'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:message, :template_path)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {
          'template_path' => template_path
        },
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }
  end

  describe '#message' do
    let(:expected) do
      "unable to load template #{template_path}"
    end

    include_examples 'should define reader', :message, -> { be == expected }

    context 'when initialized with message: value' do
      let(:message)  { 'Something went wrong' }
      let(:options)  { super().merge(message:) }
      let(:expected) { "#{message} - #{super()}" }

      it { expect(error.message).to be == expected }
    end
  end

  describe '#template_path' do
    include_examples 'should define reader',
      :template_path,
      -> { template_path }
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
