# frozen_string_literal: true

require 'cuprum/cli/errors/files/file_not_writeable'

RSpec.describe Cuprum::Cli::Errors::Files::FileNotWriteable do
  subject(:error) { described_class.new(file_path:, **options) }

  let(:file_path) { 'path/to/file.txt' }
  let(:options)   { {} }

  describe '::TYPE' do
    include_examples 'should define immutable constant',
      :TYPE,
      'cuprum.cli.errors.files.file_not_writeable'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:file_path, :message, :reason)
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

    context 'when initialized with reason: value' do
      let(:reason)  { 'indeterminate quantum state' }
      let(:options) { super().merge(reason:) }
      let(:expected) do
        {
          'data'    => {
            'file_path' => file_path,
            'reason'    => reason
          },
          'message' => error.message,
          'type'    => error.type
        }
      end

      it { expect(error.as_json).to be == expected }
    end
  end

  describe '#file_path' do
    include_examples 'should define reader', :file_path, -> { file_path }
  end

  describe '#message' do
    let(:expected) do
      "unable to write file #{file_path}"
    end

    include_examples 'should define reader', :message, -> { expected }

    context 'when initialized with message: value' do
      let(:message)  { 'something went wrong' }
      let(:options)  { super().merge(message:) }
      let(:expected) { message }

      it { expect(error.message).to be == expected }

      context 'when initialized with reason: value' do
        let(:reason)   { 'indeterminate quantum state' }
        let(:options)  { super().merge(reason:) }
        let(:expected) { "#{super()} - #{reason}" }

        it { expect(error.message).to be == expected }
      end
    end

    context 'when initialized with reason: value' do
      let(:reason)   { 'indeterminate quantum state' }
      let(:options)  { super().merge(reason:) }
      let(:expected) { "#{super()} - #{reason}" }

      it { expect(error.message).to be == expected }
    end
  end

  describe '#reason' do
    include_examples 'should define reader', :reason, nil

    context 'when initialized with reason: value' do
      let(:reason)  { 'indeterminate quantum state' }
      let(:options) { super().merge(reason:) }

      it { expect(error.reason).to be == reason }
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
