# frozen_string_literal: true

require 'cuprum/cli/errors/files/missing_parameter'

RSpec.describe Cuprum::Cli::Errors::Files::MissingParameter do
  subject(:error) { described_class.new(parameter_name:, **options) }

  let(:parameter_name) { 'widget' }
  let(:options)        { {} }

  describe '::TYPE' do
    include_examples 'should define immutable constant',
      :TYPE,
      'cuprum.cli.errors.files.missing_parameter'
  end

  describe '.new' do
    let(:expected_keywords) do
      %i[
        details
        format
        message
        parameter_name
        template_name
      ]
    end

    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(*expected_keywords)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {
          'parameter_name' => error.parameter_name.to_s
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
            'details'        => error.details,
            'parameter_name' => error.parameter_name.to_s
          },
          'message' => error.message,
          'type'    => error.type
        }
      end

      it { expect(error.as_json).to be == expected }
    end

    context 'when initialized with format: value' do
      let(:format)  { '.erb' }
      let(:options) { super().merge(format:) }
      let(:expected) do
        {
          'data'    => {
            'format'         => error.format,
            'parameter_name' => error.parameter_name.to_s
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
            'parameter_name' => error.parameter_name.to_s,
            'template_name'  => template_name
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

  describe '#format' do
    include_examples 'should define reader', :format, nil

    context 'when initialized with format: value' do
      let(:format)  { '.erb' }
      let(:options) { super().merge(format:) }

      it { expect(error.format).to be == format }
    end
  end

  describe '#message' do
    let(:expected) { "missing parameter #{parameter_name.inspect}" }

    include_examples 'should define reader', :message, -> { expected }

    context 'when initialized with format: value' do
      let(:format)   { '.erb' }
      let(:options)  { super().merge(format:) }
      let(:expected) { "#{super()} for #{format} template" }

      it { expect(error.message).to be == expected }
    end

    context 'when initialized with message: value' do
      let(:message)  { 'Something went wrong' }
      let(:options)  { super().merge(message:) }
      let(:expected) { "#{message} - #{super()}" }

      it { expect(error.message).to be == expected }
    end

    context 'when initialized with template_name: value' do
      let(:template_name) { 'template.html.erb' }
      let(:options)       { super().merge(template_name:) }
      let(:expected)      { "#{super()} for template #{template_name}" }

      it { expect(error.message).to be == expected }

      context 'when initialized with format: value' do
        let(:format)   { '.erb' }
        let(:options)  { super().merge(format:) }
        let(:expected) { "#{super()} with format #{format}" }

        it { expect(error.message).to be == expected }
      end
    end

    context 'when initialized with multiple options' do
      let(:format)        { '.erb' }
      let(:message)       { 'Something went wrong' }
      let(:template_name) { 'template.html.erb' }
      let(:options)       { super().merge(format:, message:, template_name:) }
      let(:expected) do
        "#{message} - #{super()} for template #{template_name} with format " \
          "#{format}"
      end

      it { expect(error.message).to be == expected }
    end
  end

  describe '#parameter_name' do
    include_examples 'should define reader',
      :parameter_name,
      -> { parameter_name }
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
