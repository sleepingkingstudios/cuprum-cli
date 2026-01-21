# frozen_string_literal: true

require 'cuprum/cli/options/class_methods'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Options::ClassMethods do
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  deferred_context 'when the command has a parent command' do
    let(:described_class) { Spec::SubclassCommand }

    example_class 'Spec::SubclassCommand', 'Spec::Command'
  end

  deferred_context 'when the command has many options' do
    before(:example) do
      described_class.option :color, type:     :integer
      described_class.option :shape, required: true
    end
  end

  deferred_context 'when the parent command has many options' do
    before(:example) do
      Spec::Command.option :size,        default: 'medium'
      Spec::Command.option :transparent, type:    :boolean
    end
  end

  let(:described_class) { Spec::Command }

  example_class 'Spec::Command' do |klass|
    klass.extend Cuprum::Cli::Options::ClassMethods # rubocop:disable RSpec/DescribedClass
  end

  describe '.option' do
    deferred_examples 'should define the option' do
      context 'when the option is defined' do
        before(:example) { described_class.option(name, **options) }

        include_deferred 'should define option', :format
      end

      describe 'with aliases: value' do
        let(:options) { super().merge(aliases: 'f') }

        context 'when the option is defined' do
          before(:example) { described_class.option(name, **options) }

          include_deferred 'should define option', :format, aliases: %w[f]
        end
      end

      describe 'with default: value' do
        let(:options) { super().merge(default: :json) }

        context 'when the option is defined' do
          before(:example) { described_class.option(name, **options) }

          include_deferred 'should define option', :format, default: :json
        end
      end

      describe 'with description: value' do
        let(:description) do
          'The output format for the command.'
        end
        let(:options) { super().merge(description:) }

        context 'when the option is defined' do
          before(:example) { described_class.option(name, **options) }

          include_deferred 'should define option',
            :format,
            description: -> { description }
        end
      end

      describe 'with required: true' do
        let(:options) { super().merge(required: true) }

        context 'when the option is defined' do
          before(:example) { described_class.option(name, **options) }

          include_deferred 'should define option', :format, required: true
        end
      end

      describe 'with type: value' do
        let(:options) { super().merge(type: :boolean) }

        context 'when the option is defined' do
          before(:example) { described_class.option(name, **options) }

          include_deferred 'should define option', :format, type: :boolean
        end
      end
    end

    let(:name)    { :format }
    let(:options) { {} }
    let(:expected_keywords) do
      %i[
        aliases
        default
        description
        name
        required
        type
      ]
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:option)
        .with(1).argument
        .and_keywords(*expected_keywords)
    end

    describe 'with name: a String' do
      let(:name) { 'format' }

      it { expect(described_class.option(name)).to be name.to_sym }

      include_deferred 'should define the option'
    end

    describe 'with name: a Symbol' do
      let(:name) { :format }

      it { expect(described_class.option(name)).to be name }

      include_deferred 'should define the option'
    end
  end

  describe '.options' do
    it { expect(described_class).to respond_to(:options).with(0).arguments }

    it { expect(described_class.options).to be == {} }

    wrap_deferred 'when the command has many options' do
      let(:expected_keys) { %i[color shape] }

      it 'should define the expected options' do
        expect(described_class.options.keys).to match_array(expected_keys)
      end

      it { expect(described_class.options[:color].type).to be :integer }
    end

    wrap_deferred 'when the command has a parent command' do
      it { expect(described_class.options).to be == {} }

      wrap_deferred 'when the command has many options' do
        let(:expected_keys) { %i[color shape] }

        it 'should define the expected options' do
          expect(described_class.options.keys).to match_array(expected_keys)
        end

        it { expect(described_class.options[:color].type).to be :integer }
      end

      wrap_deferred 'when the parent command has many options' do
        let(:expected_keys) { %i[size transparent] }

        it 'should define the expected options' do
          expect(described_class.options.keys).to match_array(expected_keys)
        end

        it { expect(described_class.options[:transparent].type).to be :boolean }
      end

      context 'when the command and parent command have many options' do
        let(:expected_keys) { %i[color shape size transparent] }

        include_deferred 'when the command has many options'
        include_deferred 'when the parent command has many options'

        it 'should define the expected options' do
          expect(described_class.options.keys).to match_array(expected_keys)
        end
      end
    end
  end

  describe '.resolve_options' do
    let(:values) { {} }

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:resolve_options)
        .with(0).arguments
        .and_any_keywords
    end

    describe 'with no values' do
      it { expect(described_class.resolve_options).to be == {} }
    end

    describe 'with one unknown option value' do
      let(:values) { super().merge(unknown: 'value') }
      let(:error_message) do
        "unrecognized option :unknown for #{described_class.name}"
      end

      it 'should raise an exception' do
        expect { described_class.resolve_options(**values) }
          .to raise_error Cuprum::Cli::Errors::UnknownOptionError, error_message
      end
    end

    describe 'with many unknown option values' do
      let(:values) { super().merge(unknown: 'value', mystery: 'value') }
      let(:error_message) do
        "unrecognized options :unknown, :mystery for #{described_class.name}"
      end

      it 'should raise an exception' do
        expect { described_class.resolve_options(**values) }
          .to raise_error Cuprum::Cli::Errors::UnknownOptionError, error_message
      end
    end

    context 'when the command and parent command have many options' do
      include_deferred 'when the command has a parent command'
      include_deferred 'when the command has many options'
      include_deferred 'when the parent command has many options'

      describe 'with no values' do
        let(:error_message) do
          'invalid value for option :shape - expected an instance of String, ' \
            'received nil'
        end

        it 'should raise an exception' do
          expect { described_class.resolve_options }
            .to raise_error Cuprum::Cli::Errors::InvalidOptionError, error_message
        end
      end

      describe 'with missing values' do
        let(:values) { { transparent: true } }
        let(:error_message) do
          'invalid value for option :shape - expected an instance of String, ' \
            'received nil'
        end

        it 'should raise an exception' do
          expect { described_class.resolve_options }
            .to raise_error Cuprum::Cli::Errors::InvalidOptionError, error_message
        end
      end

      describe 'with valid values' do
        let(:values)   { { shape: 'triangle', transparent: true } }
        let(:expected) { values.merge(color: nil, size: 'medium') }

        it 'should apply the option defaults' do
          expect(described_class.resolve_options(**values)).to be == expected
        end
      end

      describe 'with extra values' do
        let(:values) do
          { shape: 'triangle', transparent: true, unknown: 'value' }
        end
        let(:error_message) do
          "unrecognized option :unknown for #{described_class.name} - valid " \
            'options are :color, :shape, :size, :transparent'
        end

        it 'should raise an exception' do
          expect { described_class.resolve_options(**values) }
            .to raise_error(
              Cuprum::Cli::Errors::UnknownOptionError,
              error_message
            )
        end
      end
    end
  end
end
