# frozen_string_literal: true

require 'cuprum/cli/option'

RSpec.describe Cuprum::Cli::Option do
  subject(:option) { described_class.new(name:, **constructor_options) }

  let(:name)                { :format }
  let(:constructor_options) { {} }

  describe '.new' do
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

    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(*expected_keywords)
    end
  end

  describe '#aliases' do
    include_examples 'should define reader', :aliases, []

    context 'when initialized with aliases: a String' do
      let(:expected)            { %w[f] }
      let(:constructor_options) { super().merge(aliases: 'f') }

      it { expect(option.aliases).to be == expected }
    end

    context 'when initialized with aliases: a Symbol' do
      let(:expected)            { %w[f] }
      let(:constructor_options) { super().merge(aliases: :f) }

      it { expect(option.aliases).to be == expected }
    end

    context 'when initialized with aliases: an Array of Strings' do
      let(:aliases)             { %w[f output_format] }
      let(:expected)            { %w[f output-format] }
      let(:constructor_options) { super().merge(aliases:) }

      it { expect(option.aliases).to be == expected }
    end

    context 'when initialized with aliases: an Array of Symbols' do
      let(:aliases)             { %i[f output_format] }
      let(:expected)            { %w[f output-format] }
      let(:constructor_options) { super().merge(aliases:) }

      it { expect(option.aliases).to be == expected }
    end
  end

  describe '#default' do
    include_examples 'should define reader', :default, nil

    context 'when initialized with default: a Proc' do
      let(:default)             { -> { :json } }
      let(:constructor_options) { super().merge(default:) }

      it { expect(option.default).to be default }
    end

    context 'when initialized with default: value' do
      let(:default)             { :documentation }
      let(:constructor_options) { super().merge(default:) }

      it { expect(option.default).to be default }
    end
  end

  describe '#description' do
    include_examples 'should define reader', :description, nil

    context 'when initialized with description: value' do
      let(:description) do
        'The output format for the command.'
      end
      let(:constructor_options) { super().merge(description:) }

      it { expect(option.description).to be == description }
    end
  end

  describe '#name' do
    include_examples 'should define reader', :name, -> { name }
  end

  describe '#required' do
    include_examples 'should define reader', :required, false

    it { expect(option).to have_aliased_method(:required).as(:required?) }

    context 'when initialized with required: nil' do
      let(:constructor_options) { super().merge(required: nil) }

      it { expect(option.required).to be false }
    end

    context 'when initialized with required: an Object' do
      let(:constructor_options) { super().merge(required: Object.new.freeze) }

      it { expect(option.required).to be true }
    end

    context 'when initialized with required: false' do
      let(:constructor_options) { super().merge(required: false) }

      it { expect(option.required).to be false }
    end

    context 'when initialized with required: true' do
      let(:constructor_options) { super().merge(required: true) }

      it { expect(option.required).to be true }
    end
  end

  describe '#resolve' do
    it { expect(option).to respond_to(:resolve).with(1).argument }

    describe 'with nil' do
      it { expect(option.resolve(nil)).to be nil }

      context 'when initialized with default: a Proc' do
        let(:default)             { -> { :json } }
        let(:constructor_options) { super().merge(default:) }

        it { expect(option.resolve(nil)).to be == 'json' }
      end

      context 'when initialized with default: value' do
        let(:default)             { :documentation }
        let(:constructor_options) { super().merge(default:) }

        it { expect(option.resolve(nil)).to be == 'documentation' }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }
        let(:error_message) do
          'invalid value for option :format - expected an instance of ' \
            'String, received nil'
        end

        it 'should raise an exception' do
          expect { option.resolve(nil) }
            .to raise_error(
              Cuprum::Cli::Errors::InvalidOptionError,
              error_message
            )
        end
      end
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }
      let(:error_message) do
        'invalid value for option :format - expected an instance of ' \
          "String, received #{value.inspect}"
      end

      it 'should raise an exception' do
        expect { option.resolve(value) }
          .to raise_error(
            Cuprum::Cli::Errors::InvalidOptionError,
            error_message
          )
      end
    end

    describe 'with an empty String' do
      it { expect(option.resolve('')).to be nil }

      context 'when initialized with default: a Proc' do
        let(:default)             { -> { :json } }
        let(:constructor_options) { super().merge(default:) }

        it { expect(option.resolve('')).to be == 'json' }
      end

      context 'when initialized with default: value' do
        let(:default)             { :documentation }
        let(:constructor_options) { super().merge(default:) }

        it { expect(option.resolve('')).to be == 'documentation' }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }
        let(:error_message) do
          'invalid value for option :format - expected an instance of ' \
            'String, received ""'
        end

        it 'should raise an exception' do
          expect { option.resolve('') }
            .to raise_error(
              Cuprum::Cli::Errors::InvalidOptionError,
              error_message
            )
        end
      end
    end

    describe 'with an empty Symbol' do
      it { expect(option.resolve(:'')).to be nil }

      context 'when initialized with default: a Proc' do
        let(:default)             { -> { :json } }
        let(:constructor_options) { super().merge(default:) }

        it { expect(option.resolve(:'')).to be == 'json' }
      end

      context 'when initialized with default: value' do
        let(:default)             { :documentation }
        let(:constructor_options) { super().merge(default:) }

        it { expect(option.resolve(:'')).to be == 'documentation' }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }
        let(:error_message) do
          'invalid value for option :format - expected an instance of ' \
            'String, received :""'
        end

        it 'should raise an exception' do
          expect { option.resolve(:'') }
            .to raise_error(
              Cuprum::Cli::Errors::InvalidOptionError,
              error_message
            )
        end
      end
    end

    describe 'with a non-empty String' do
      let(:value) { 'documentation' }

      it { expect(option.resolve(value)).to be value }

      context 'when initialized with default: a Proc' do
        let(:default)             { -> { :json } }
        let(:constructor_options) { super().merge(default:) }

        it { expect(option.resolve(value)).to be value }
      end

      context 'when initialized with default: value' do
        let(:default)             { :documentation }
        let(:constructor_options) { super().merge(default:) }

        it { expect(option.resolve(value)).to be value }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }

        it { expect(option.resolve(value)).to be value }
      end
    end

    describe 'with a non-empty Symbol' do
      let(:value) { :progress }

      it { expect(option.resolve(value)).to be == 'progress' }

      context 'when initialized with default: a Proc' do
        let(:default)             { -> { :json } }
        let(:constructor_options) { super().merge(default:) }

        it { expect(option.resolve(value)).to be == 'progress' }
      end

      context 'when initialized with default: value' do
        let(:default)             { :documentation }
        let(:constructor_options) { super().merge(default:) }

        it { expect(option.resolve(value)).to be == 'progress' }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }

        it { expect(option.resolve(value)).to be == 'progress' }
      end
    end

    context 'when initialized with type: :boolean' do
      let(:constructor_options) { super().merge(type: :boolean) }

      describe 'with nil' do
        it { expect(option.resolve(nil)).to be false }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { false } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(option.resolve(nil)).to be false }
        end

        context 'when initialized with default: value' do
          let(:default)             { true }
          let(:constructor_options) { super().merge(default:) }

          it { expect(option.resolve(nil)).to be true }
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }
          let(:error_message) do
            'invalid value for option :format - expected true or false, ' \
              'received nil'
          end

          it 'should raise an exception' do
            expect { option.resolve(nil) }
              .to raise_error(
                Cuprum::Cli::Errors::InvalidOptionError,
                error_message
              )
          end
        end
      end

      describe 'with an Object' do
        let(:value) { Object.new.freeze }
        let(:error_message) do
          'invalid value for option :format - expected true or false, ' \
            "received #{value.inspect}"
        end

        it 'should raise an exception' do
          expect { option.resolve(value) }
            .to raise_error(
              Cuprum::Cli::Errors::InvalidOptionError,
              error_message
            )
        end
      end

      describe 'with false' do
        it { expect(option.resolve(false)).to be false }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { true } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(option.resolve(false)).to be false }
        end

        context 'when initialized with default: value' do
          let(:default)             { true }
          let(:constructor_options) { super().merge(default:) }

          it { expect(option.resolve(false)).to be false }
        end
      end

      describe 'with true' do
        it { expect(option.resolve(true)).to be true }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { false } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(option.resolve(true)).to be true }
        end

        context 'when initialized with default: value' do
          let(:default)             { false }
          let(:constructor_options) { super().merge(default:) }

          it { expect(option.resolve(true)).to be true }
        end
      end
    end

    context 'when initialized with type: a Class' do
      let(:constructor_options) { super().merge(type: Integer) }

      describe 'with nil' do
        it { expect(option.resolve(nil)).to be nil }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { 21 * 2 } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(option.resolve(nil)).to be 42 }
        end

        context 'when initialized with default: value' do
          let(:default)             { 42 }
          let(:constructor_options) { super().merge(default:) }

          it { expect(option.resolve(nil)).to be 42 }
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }
          let(:error_message) do
            'invalid value for option :format - expected an instance of ' \
              'Integer, received nil'
          end

          it 'should raise an exception' do
            expect { option.resolve(nil) }
              .to raise_error(
                Cuprum::Cli::Errors::InvalidOptionError,
                error_message
              )
          end
        end
      end

      describe 'with an Object' do
        let(:value) { Object.new.freeze }
        let(:error_message) do
          'invalid value for option :format - expected an instance of ' \
            "Integer, received #{value.inspect}"
        end

        it 'should raise an exception' do
          expect { option.resolve(value) }
            .to raise_error(
              Cuprum::Cli::Errors::InvalidOptionError,
              error_message
            )
        end
      end

      describe 'with an instance of the Class' do
        let(:value) { 32_768 }

        it { expect(option.resolve(value)).to be value }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { 21 * 2 } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(option.resolve(value)).to be value }
        end

        context 'when initialized with default: value' do
          let(:default)             { 42 }
          let(:constructor_options) { super().merge(default:) }

          it { expect(option.resolve(value)).to be value }
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }

          it { expect(option.resolve(value)).to be value }
        end
      end
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, :string

    context 'when initialized with type: a Class' do
      let(:constructor_options) { super().merge(type: Integer) }

      it { expect(option.type).to be Integer }
    end

    context 'when initialized with type: a String' do
      let(:constructor_options) { super().merge(type: 'symbol') }

      it { expect(option.type).to be :symbol }
    end

    context 'when initialized with type: a Symbol' do
      let(:constructor_options) { super().merge(type: :boolean) }

      it { expect(option.type).to be :boolean }
    end
  end
end
