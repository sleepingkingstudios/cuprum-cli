# frozen_string_literal: true

require 'cuprum/cli/argument'

RSpec.describe Cuprum::Cli::Argument do
  subject(:argument) { described_class.new(name:, **constructor_options) }

  let(:name)                { :format }
  let(:constructor_options) { {} }

  describe '.new' do
    let(:expected_keywords) do
      %i[
        default
        description
        name
        required
        type
        variadic
      ]
    end

    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(*expected_keywords)
    end
  end

  describe '#default' do
    include_examples 'should define reader', :default, nil

    context 'when initialized with default: a Proc' do
      let(:default)             { -> { :json } }
      let(:constructor_options) { super().merge(default:) }

      it { expect(argument.default).to be default }
    end

    context 'when initialized with default: value' do
      let(:default)             { :documentation }
      let(:constructor_options) { super().merge(default:) }

      it { expect(argument.default).to be default }
    end
  end

  describe '#description' do
    include_examples 'should define reader', :description, nil

    context 'when initialized with description: value' do
      let(:description) do
        'The output format for the command.'
      end
      let(:constructor_options) { super().merge(description:) }

      it { expect(argument.description).to be == description }
    end
  end

  describe '#name' do
    include_examples 'should define reader', :name, -> { name }
  end

  describe '#required' do
    include_examples 'should define reader', :required, false

    it { expect(argument).to have_aliased_method(:required).as(:required?) }

    context 'when initialized with required: nil' do
      let(:constructor_options) { super().merge(required: nil) }

      it { expect(argument.required).to be false }
    end

    context 'when initialized with required: an Object' do
      let(:constructor_options) { super().merge(required: Object.new.freeze) }

      it { expect(argument.required).to be true }
    end

    context 'when initialized with required: false' do
      let(:constructor_options) { super().merge(required: false) }

      it { expect(argument.required).to be false }
    end

    context 'when initialized with required: true' do
      let(:constructor_options) { super().merge(required: true) }

      it { expect(argument.required).to be true }
    end
  end

  describe '#resolve' do
    it { expect(argument).to respond_to(:resolve).with(1).argument }

    describe 'with nil' do
      it { expect(argument.resolve(nil)).to be nil }

      context 'when initialized with default: a Proc' do
        let(:default)             { -> { :json } }
        let(:constructor_options) { super().merge(default:) }

        it { expect(argument.resolve(nil)).to be == 'json' }
      end

      context 'when initialized with default: value' do
        let(:default)             { :documentation }
        let(:constructor_options) { super().merge(default:) }

        it { expect(argument.resolve(nil)).to be == 'documentation' }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }
        let(:error_message) do
          'invalid value for argument :format - expected an instance of ' \
            'String, received nil'
        end

        it 'should raise an exception' do
          expect { argument.resolve(nil) }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end
      end
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }
      let(:error_message) do
        'invalid value for argument :format - expected an instance of ' \
          "String, received #{value.inspect}"
      end

      it 'should raise an exception' do
        expect { argument.resolve(value) }
          .to raise_error(
            Cuprum::Cli::Arguments::InvalidArgumentError,
            error_message
          )
      end
    end

    describe 'with an empty String' do
      it { expect(argument.resolve('')).to be nil }

      context 'when initialized with default: a Proc' do
        let(:default)             { -> { :json } }
        let(:constructor_options) { super().merge(default:) }

        it { expect(argument.resolve('')).to be == 'json' }
      end

      context 'when initialized with default: value' do
        let(:default)             { :documentation }
        let(:constructor_options) { super().merge(default:) }

        it { expect(argument.resolve('')).to be == 'documentation' }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }
        let(:error_message) do
          'invalid value for argument :format - expected an instance of ' \
            'String, received ""'
        end

        it 'should raise an exception' do
          expect { argument.resolve('') }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end
      end
    end

    describe 'with an empty Symbol' do
      it { expect(argument.resolve(:'')).to be nil }

      context 'when initialized with default: a Proc' do
        let(:default)             { -> { :json } }
        let(:constructor_options) { super().merge(default:) }

        it { expect(argument.resolve(:'')).to be == 'json' }
      end

      context 'when initialized with default: value' do
        let(:default)             { :documentation }
        let(:constructor_options) { super().merge(default:) }

        it { expect(argument.resolve(:'')).to be == 'documentation' }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }
        let(:error_message) do
          'invalid value for argument :format - expected an instance of ' \
            'String, received :""'
        end

        it 'should raise an exception' do
          expect { argument.resolve(:'') }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end
      end
    end

    describe 'with a non-empty String' do
      let(:value) { 'documentation' }

      it { expect(argument.resolve(value)).to be value }

      context 'when initialized with default: a Proc' do
        let(:default)             { -> { :json } }
        let(:constructor_options) { super().merge(default:) }

        it { expect(argument.resolve(value)).to be value }
      end

      context 'when initialized with default: value' do
        let(:default)             { :documentation }
        let(:constructor_options) { super().merge(default:) }

        it { expect(argument.resolve(value)).to be value }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }

        it { expect(argument.resolve(value)).to be value }
      end
    end

    describe 'with a non-empty Symbol' do
      let(:value) { :progress }

      it { expect(argument.resolve(value)).to be == 'progress' }

      context 'when initialized with default: a Proc' do
        let(:default)             { -> { :json } }
        let(:constructor_options) { super().merge(default:) }

        it { expect(argument.resolve(value)).to be == 'progress' }
      end

      context 'when initialized with default: value' do
        let(:default)             { :documentation }
        let(:constructor_options) { super().merge(default:) }

        it { expect(argument.resolve(value)).to be == 'progress' }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }

        it { expect(argument.resolve(value)).to be == 'progress' }
      end
    end

    context 'when initialized with type: :boolean' do
      let(:constructor_options) { super().merge(type: :boolean) }

      describe 'with nil' do
        it { expect(argument.resolve(nil)).to be false }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { false } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(nil)).to be false }
        end

        context 'when initialized with default: value' do
          let(:default)             { true }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(nil)).to be true }
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }
          let(:error_message) do
            'invalid value for argument :format - expected true or false, ' \
              'received nil'
          end

          it 'should raise an exception' do
            expect { argument.resolve(nil) }
              .to raise_error(
                Cuprum::Cli::Arguments::InvalidArgumentError,
                error_message
              )
          end
        end
      end

      describe 'with an Object' do
        let(:value) { Object.new.freeze }
        let(:error_message) do
          'invalid value for argument :format - expected true or false, ' \
            "received #{value.inspect}"
        end

        it 'should raise an exception' do
          expect { argument.resolve(value) }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end
      end

      describe 'with false' do
        it { expect(argument.resolve(false)).to be false }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { true } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(false)).to be false }
        end

        context 'when initialized with default: value' do
          let(:default)             { true }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(false)).to be false }
        end
      end

      describe 'with true' do
        it { expect(argument.resolve(true)).to be true }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { false } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(true)).to be true }
        end

        context 'when initialized with default: value' do
          let(:default)             { false }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(true)).to be true }
        end
      end
    end

    context 'when initialized with type: a Class' do
      let(:constructor_options) { super().merge(type: Integer) }

      describe 'with nil' do
        it { expect(argument.resolve(nil)).to be nil }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { 21 * 2 } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(nil)).to be 42 }
        end

        context 'when initialized with default: value' do
          let(:default)             { 42 }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(nil)).to be 42 }
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }
          let(:error_message) do
            'invalid value for argument :format - expected an instance of ' \
              'Integer, received nil'
          end

          it 'should raise an exception' do
            expect { argument.resolve(nil) }
              .to raise_error(
                Cuprum::Cli::Arguments::InvalidArgumentError,
                error_message
              )
          end
        end
      end

      describe 'with an Object' do
        let(:value) { Object.new.freeze }
        let(:error_message) do
          'invalid value for argument :format - expected an instance of ' \
            "Integer, received #{value.inspect}"
        end

        it 'should raise an exception' do
          expect { argument.resolve(value) }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end
      end

      describe 'with an instance of the Class' do
        let(:value) { 32_768 }

        it { expect(argument.resolve(value)).to be value }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { 21 * 2 } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(value)).to be value }
        end

        context 'when initialized with default: value' do
          let(:default)             { 42 }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(value)).to be value }
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }

          it { expect(argument.resolve(value)).to be value }
        end
      end
    end

    describe 'when initialized with variadic: true' do
      let(:constructor_options) { super().merge(variadic: true) }

      describe 'with nil' do
        it { expect(argument.resolve(nil)).to be == [] }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { %w[json progress] } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(nil)).to be == %w[json progress] }
        end

        context 'when initialized with default: value' do
          let(:default)             { %w[documentation] }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(nil)).to be == %w[documentation] }
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }
          let(:error_message) do
            'invalid value for variadic argument :format - expected a ' \
              'non-empty Array of Strings, received nil'
          end

          it 'should raise an exception' do
            expect { argument.resolve(nil) }
              .to raise_error(
                Cuprum::Cli::Arguments::InvalidArgumentError,
                error_message
              )
          end
        end
      end

      describe 'with an Object' do
        let(:value) { Object.new.freeze }
        let(:error_message) do
          'invalid value for variadic argument :format - expected an Array ' \
            "of Strings, received #{value.inspect}"
        end

        it 'should raise an exception' do
          expect { argument.resolve(value) }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }
          let(:error_message) do
            'invalid value for variadic argument :format - expected a ' \
              "non-empty Array of Strings, received #{value.inspect}"
          end

          it 'should raise an exception' do
            expect { argument.resolve(value) }
              .to raise_error(
                Cuprum::Cli::Arguments::InvalidArgumentError,
                error_message
              )
          end
        end
      end

      describe 'with an empty Array' do
        it { expect(argument.resolve([])).to be == [] }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { %w[json progress] } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve([])).to be == %w[json progress] }
        end

        context 'when initialized with default: value' do
          let(:default)             { %w[documentation] }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve([])).to be == %w[documentation] }
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }
          let(:error_message) do
            'invalid value for variadic argument :format - expected a ' \
              'non-empty Array of Strings, received []'
          end

          it 'should raise an exception' do
            expect { argument.resolve([]) }
              .to raise_error(
                Cuprum::Cli::Arguments::InvalidArgumentError,
                error_message
              )
          end
        end
      end

      describe 'with an Array with invalid items' do
        let(:value) { [0, 1, 2] }
        let(:error_message) do
          'invalid value for variadic argument :format - expected an Array ' \
            "of Strings, received #{value.inspect}"
        end

        it 'should raise an exception' do
          expect { argument.resolve(value) }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }
          let(:error_message) do
            'invalid value for variadic argument :format - expected a ' \
              "non-empty Array of Strings, received #{value.inspect}"
          end

          it 'should raise an exception' do
            expect { argument.resolve(value) }
              .to raise_error(
                Cuprum::Cli::Arguments::InvalidArgumentError,
                error_message
              )
          end
        end
      end

      describe 'with an Array with valid items' do
        let(:value) { %w[smoke mirrors] }

        it { expect(argument.resolve(value)).to be == value }

        context 'when initialized with default: a Proc' do
          let(:default)             { -> { %w[json progress] } }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(value)).to be == value }
        end

        context 'when initialized with default: value' do
          let(:default)             { %w[documentation] }
          let(:constructor_options) { super().merge(default:) }

          it { expect(argument.resolve(value)).to be == value }
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }

          it { expect(argument.resolve(value)).to be == value }
        end
      end

      context 'when initialized with type: :boolean' do
        let(:constructor_options) { super().merge(type: :boolean) }

        describe 'with an Array with invalid items' do
          let(:value) { [0, 1, 2] }
          let(:error_message) do
            'invalid value for variadic argument :format - expected an Array ' \
              "of true or false, received #{value.inspect}"
          end

          it 'should raise an exception' do
            expect { argument.resolve(value) }
              .to raise_error(
                Cuprum::Cli::Arguments::InvalidArgumentError,
                error_message
              )
          end

          context 'when initialized with required: true' do # rubocop:disable RSpec/NestedGroups
            let(:constructor_options) { super().merge(required: true) }
            let(:error_message) do
              'invalid value for variadic argument :format - expected a ' \
                "non-empty Array of true or false, received #{value.inspect}"
            end

            it 'should raise an exception' do
              expect { argument.resolve(value) }
                .to raise_error(
                  Cuprum::Cli::Arguments::InvalidArgumentError,
                  error_message
                )
            end
          end
        end
      end

      context 'when initialized with type: a Class' do
        let(:constructor_options) { super().merge(type: Integer) }

        describe 'with an Array with invalid items' do
          let(:value) { %w[smoke mirrors] }
          let(:error_message) do
            'invalid value for variadic argument :format - expected an Array ' \
              "of Integers, received #{value.inspect}"
          end

          it 'should raise an exception' do
            expect { argument.resolve(value) }
              .to raise_error(
                Cuprum::Cli::Arguments::InvalidArgumentError,
                error_message
              )
          end

          context 'when initialized with required: true' do # rubocop:disable RSpec/NestedGroups
            let(:constructor_options) { super().merge(required: true) }
            let(:error_message) do
              'invalid value for variadic argument :format - expected a ' \
                "non-empty Array of Integers, received #{value.inspect}"
            end

            it 'should raise an exception' do
              expect { argument.resolve(value) }
                .to raise_error(
                  Cuprum::Cli::Arguments::InvalidArgumentError,
                  error_message
                )
            end
          end
        end
      end
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, :string

    context 'when initialized with type: a Class' do
      let(:constructor_options) { super().merge(type: Integer) }

      it { expect(argument.type).to be Integer }
    end

    context 'when initialized with type: a String' do
      let(:constructor_options) { super().merge(type: 'symbol') }

      it { expect(argument.type).to be :symbol }
    end

    context 'when initialized with type: a Symbol' do
      let(:constructor_options) { super().merge(type: :boolean) }

      it { expect(argument.type).to be :boolean }
    end
  end

  describe '#variadic' do
    include_examples 'should define reader', :variadic, false

    it { expect(argument).to have_aliased_method(:variadic).as(:variadic?) }

    context 'when initialized with variadic: nil' do
      let(:constructor_options) { super().merge(variadic: nil) }

      it { expect(argument.variadic).to be false }
    end

    context 'when initialized with variadic: an Object' do
      let(:constructor_options) { super().merge(variadic: Object.new.freeze) }

      it { expect(argument.variadic).to be true }
    end

    context 'when initialized with variadic: false' do
      let(:constructor_options) { super().merge(variadic: false) }

      it { expect(argument.variadic).to be false }
    end

    context 'when initialized with variadic: true' do
      let(:constructor_options) { super().merge(variadic: true) }

      it { expect(argument.variadic).to be true }
    end
  end
end
