# frozen_string_literal: true

require 'cuprum/cli/arguments/class_methods'
require 'cuprum/cli/rspec/deferred/arguments_examples'

RSpec.describe Cuprum::Cli::Arguments::ClassMethods do
  include Cuprum::Cli::RSpec::Deferred::ArgumentsExamples

  subject(:command) { Spec::Command.new(constructor_options) }

  deferred_context 'when the command has many arguments' do
    before(:example) do
      described_class.argument :color, required: true, type: :integer
      described_class.argument :shape
    end
  end

  deferred_context 'when the command has a variadic argument' do
    before(:example) do
      described_class.argument :color, required: true, type: :integer
      described_class.argument :shape
      described_class.argument :sizes, variadic: true
      described_class.argument :transparency
    end
  end

  let(:described_class)     { Spec::Command }
  let(:constructor_options) { {} }

  example_class 'Spec::Command' do |klass|
    klass.extend Cuprum::Cli::Arguments::ClassMethods # rubocop:disable RSpec/DescribedClass

    klass.define_method(:initialize) { |arguments| @arguments = arguments }
  end

  describe '.argument' do
    deferred_examples 'should define the argument' do
      context 'when the argument is defined' do
        before(:example) { described_class.argument(name, **options) }

        include_deferred 'should define argument', 0, :format

        describe '#:argument_name' do
          context 'when the argument has a value' do
            let(:value)               { "#{name} value" }
            let(:constructor_options) { super().merge(name.to_sym => value) }

            it { expect(command.public_send(name)).to be == value }
          end
        end
      end

      describe 'with default: value' do
        let(:options) { super().merge(default: :json) }

        context 'when the argument is defined' do
          before(:example) { described_class.argument(name, **options) }

          include_deferred 'should define argument', 0, :format, default: :json
        end
      end

      describe 'with define_method: false' do
        let(:options) { super().merge(define_method: false) }

        context 'when the argument is defined' do
          before(:example) { described_class.argument(name, **options) }

          include_deferred 'should define argument',
            0,
            :format,
            define_method: false
        end
      end

      describe 'with define_predicate: true' do
        let(:options) { super().merge(define_predicate: true) }

        context 'when the argument is defined' do
          before(:example) { described_class.argument(name, **options) }

          include_deferred 'should define argument',
            0,
            :format,
            define_predicate: true

          describe '#:argument_name?' do
            # rubocop:disable RSpec/NestedGroups
            context 'when the argument has an empty value' do
              let(:value)               { "#{name} value" }
              let(:constructor_options) { super().merge(name.to_sym => value) }

              it { expect(command.public_send("#{name}?")).to be true }
            end

            context 'when the argument has a non-empty value' do
              let(:value)               { '' }
              let(:constructor_options) { super().merge(name.to_sym => value) }

              it { expect(command.public_send("#{name}?")).to be false }
            end
            # rubocop:enable RSpec/NestedGroups
          end
        end
      end

      describe 'with description: value' do
        let(:description) do
          'The output format for the command.'
        end
        let(:options) { super().merge(description:) }

        context 'when the argument is defined' do
          before(:example) { described_class.argument(name, **options) }

          include_deferred 'should define argument',
            0,
            :format,
            description: -> { description }
        end
      end

      describe 'with required: true' do
        let(:options) { super().merge(required: true) }

        context 'when the argument is defined' do
          before(:example) { described_class.argument(name, **options) }

          include_deferred 'should define argument', 0, :format, required: true
        end
      end

      describe 'with type: value' do
        let(:options) { super().merge(type: :integer) }

        context 'when the argument is defined' do
          before(:example) { described_class.argument(name, **options) }

          include_deferred 'should define argument', 0, :format, type: :integer
        end
      end

      describe 'with type: :boolean' do
        let(:options) { super().merge(type: :boolean) }

        context 'when the argument is defined' do
          before(:example) { described_class.argument(name, **options) }

          include_deferred 'should define argument', 0, :format, type: :boolean
        end

        describe 'with define_method: false' do
          let(:options) { super().merge(define_method: true) }

          context 'when the argument is defined' do
            before(:example) { described_class.argument(name, **options) }

            include_deferred 'should define argument',
              0,
              :format,
              type:          :boolean,
              define_method: true
          end
        end

        describe 'with define_predicate: false' do
          let(:options) { super().merge(define_predicate: false) }

          context 'when the argument is defined' do
            before(:example) { described_class.argument(name, **options) }

            include_deferred 'should define argument',
              0,
              :format,
              type:             :boolean,
              define_predicate: false
          end
        end
      end

      describe 'with variadic: true' do
        let(:options) { super().merge(variadic: true) }

        context 'when the argument is defined' do
          before(:example) { described_class.argument(name, **options) }

          include_deferred 'should define argument', 0, :format, variadic: true
        end
      end

      wrap_deferred 'when the command has many arguments' do
        context 'when the argument is defined' do
          before(:example) { described_class.argument(name, **options) }

          include_deferred 'should define argument', 2, :format
        end
      end
    end

    let(:name)    { :format }
    let(:options) { {} }
    let(:expected_keywords) do
      %i[
        default
        description
        required
        type
        variadic
      ]
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:argument)
        .with(1).argument
        .and_keywords(*expected_keywords)
    end

    describe 'with name: a String' do
      let(:name) { 'format' }

      it { expect(described_class.argument(name)).to be name.to_sym }

      include_deferred 'should define the argument'
    end

    describe 'with name: a Symbol' do
      let(:name) { :format }

      it { expect(described_class.argument(name)).to be name.to_sym }

      include_deferred 'should define the argument'
    end

    wrap_deferred 'when the command has a variadic argument' do
      describe 'with variadic: true' do
        let(:options) { super().merge(variadic: true) }
        let(:error_message) do
          'command already defines variadic argument :sizes'
        end

        it 'should raise an exception' do
          expect { described_class.argument(name, **options) }
            .to raise_error ArgumentError, error_message
        end
      end
    end
  end

  describe '.arguments' do
    let(:expected_keywords) do
      %i[
        default
        description
        required
        type
      ]
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:arguments)
        .with(0..1).arguments
        .and_keywords(*expected_keywords)
    end

    describe 'with no parameters' do
      it { expect(described_class.arguments).to be == [] }

      wrap_deferred 'when the command has many arguments' do
        let(:expected_names) { %i[color shape] }

        it 'should define the expected arguments' do
          expect(described_class.arguments.map(&:name)).to be == expected_names
        end

        it { expect(described_class.arguments[0].name).to be :color }

        it { expect(described_class.arguments[0].type).to be :integer }
      end

      wrap_deferred 'when the command has a variadic argument' do
        let(:expected_names) { %i[color shape sizes transparency] }

        it 'should define the expected arguments' do
          expect(described_class.arguments.map(&:name)).to be == expected_names
        end

        it { expect(described_class.arguments[0].name).to be :color }

        it { expect(described_class.arguments[0].type).to be :integer }

        it { expect(described_class.arguments[2].name).to be :sizes }

        it { expect(described_class.arguments[2].variadic?).to be true }
      end
    end

    describe 'with an argument name' do
      let(:name)    { :formats }
      let(:options) { {} }

      it { expect(described_class.argument(name, **options)).to be name.to_sym }

      context 'when the argument is defined' do
        before(:example) { described_class.arguments(name, **options) }

        include_deferred 'should define argument', 0, :formats, variadic: true
      end

      describe 'with options' do
        let(:options) { super().merge(type: :integer) }

        context 'when the argument is defined' do
          before(:example) { described_class.arguments(name, **options) }

          include_deferred 'should define argument',
            0,
            :formats,
            type:     :integer,
            variadic: true
        end
      end

      wrap_deferred 'when the command has many arguments' do
        context 'when the argument is defined' do
          before(:example) { described_class.arguments(name, **options) }

          include_deferred 'should define argument', 2, :formats, variadic: true
        end
      end

      wrap_deferred 'when the command has a variadic argument' do
        let(:error_message) do
          'command already defines variadic argument :sizes'
        end

        it 'should raise an exception' do
          expect { described_class.arguments(name, **options) }
            .to raise_error ArgumentError, error_message
        end
      end
    end
  end

  describe '.resolve_arguments' do
    let(:values) { [] }

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:resolve_arguments)
        .with_unlimited_arguments
    end

    describe 'with no values' do
      it { expect(described_class.resolve_arguments).to be == {} }
    end

    describe 'with too many values' do
      let(:values) { %w[first last] }
      let(:error_message) do
        'wrong number of arguments (given 2, expected 0)'
      end

      it 'should raise an exception' do
        expect { described_class.resolve_arguments(*values) }
          .to raise_error(
            Cuprum::Cli::Arguments::ExtraArgumentsError,
            error_message
          )
      end
    end

    describe 'when the command has optional arguments' do
      let(:expected) do
        {
          color: nil,
          shape: 'circle',
          size:  nil
        }
      end

      before(:example) do
        described_class.argument :color, type:    :integer
        described_class.argument :shape, default: :circle
        described_class.argument :size
      end

      describe 'with no values' do
        it 'should apply the argument defaults' do
          expect(described_class.resolve_arguments).to be == expected
        end
      end

      describe 'with partial values' do
        let(:values) { [0xff3366] }
        let(:expected) do
          super().merge(color: values[0])
        end

        it 'should apply the argument defaults' do
          expect(described_class.resolve_arguments(*values)).to be == expected
        end
      end

      describe 'with invalid values' do
        let(:values) { [0xff3366, 123] }
        let(:error_message) do
          'invalid value for argument :shape - expected an instance of ' \
            'String, received 123'
        end

        it 'should raise an exception' do
          expect { described_class.resolve_arguments(*values) }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end
      end

      describe 'with full values' do
        let(:values) { [0xff3366, 'triangle', 'medium'] }
        let(:expected) do
          super().merge(color: values[0], shape: values[1], size: values[2])
        end

        it 'should apply the argument defaults' do
          expect(described_class.resolve_arguments(*values)).to be == expected
        end
      end

      describe 'with too many values' do
        let(:values) { [0xff3366, 'triangle', 'medium', 'extra', 'last'] }
        let(:error_message) do
          'wrong number of arguments (given 5, expected 0..3)'
        end

        it 'should raise an exception' do
          expect { described_class.resolve_arguments(*values) }
            .to raise_error(
              Cuprum::Cli::Arguments::ExtraArgumentsError,
              error_message
            )
        end
      end
    end

    describe 'when the command has required arguments' do
      let(:expected) do
        {
          color: nil,
          shape: nil,
          size:  'small'
        }
      end

      before(:example) do
        described_class.argument :color, required: true, type: :integer
        described_class.argument :shape, required: true
        described_class.argument :size,  default:  :small
      end

      describe 'with no values' do
        let(:error_message) do
          'invalid value for argument :color - expected an instance of ' \
            'Integer, received nil'
        end

        it 'should raise an exception' do
          expect { described_class.resolve_arguments }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end
      end

      describe 'with insufficient values' do
        let(:values) { [0xff3366] }
        let(:error_message) do
          'invalid value for argument :shape - expected an instance of ' \
            'String, received nil'
        end

        it 'should raise an exception' do
          expect { described_class.resolve_arguments(*values) }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end
      end

      describe 'with partial values' do
        let(:values) { [0xff3366, 'triangle'] }
        let(:expected) do
          super().merge(color: values[0], shape: values[1])
        end

        it 'should apply the argument defaults' do
          expect(described_class.resolve_arguments(*values)).to be == expected
        end
      end

      describe 'with invalid values' do
        let(:values) { [0xff3366, 123] }
        let(:error_message) do
          'invalid value for argument :shape - expected an instance of ' \
            'String, received 123'
        end

        it 'should raise an exception' do
          expect { described_class.resolve_arguments(*values) }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end
      end

      describe 'with full values' do
        let(:values) { [0xff3366, 'triangle', 'medium'] }
        let(:expected) do
          super().merge(color: values[0], shape: values[1], size: values[2])
        end

        it 'should apply the argument defaults' do
          expect(described_class.resolve_arguments(*values)).to be == expected
        end
      end

      describe 'with too many values' do
        let(:values) { [0xff3366, 'triangle', 'medium', 'extra', 'last'] }
        let(:error_message) do
          'wrong number of arguments (given 5, expected 2..3)'
        end

        it 'should raise an exception' do
          expect { described_class.resolve_arguments(*values) }
            .to raise_error(
              Cuprum::Cli::Arguments::ExtraArgumentsError,
              error_message
            )
        end
      end
    end

    describe 'when the command has a variadic argument' do
      let(:expected) do
        { sizes: [] }
      end

      describe 'with no other arguments' do
        before(:example) { described_class.arguments :sizes }

        describe 'with no values' do
          it { expect(described_class.resolve_arguments).to be == expected }
        end

        describe 'with one value' do
          let(:values)   { %w[small] }
          let(:expected) { super().merge(sizes: values) }

          it 'should map extra arguments to the variadic parameter' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end

        describe 'with many values' do
          let(:values)   { %w[small medium large] }
          let(:expected) { super().merge(sizes: values) }

          it 'should map extra arguments to the variadic parameter' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end
      end

      describe 'with arguments after the variadic argument' do
        let(:expected) { super().merge(background: nil, transparency: false) }

        before(:example) do
          described_class.arguments :sizes
          described_class.argument  :transparency, type: :boolean
          described_class.argument  :background
        end

        describe 'with no values' do
          it { expect(described_class.resolve_arguments).to be == expected }
        end

        describe 'with partial values' do
          let(:values)   { [true] }
          let(:expected) { super().merge(transparency: true) }

          it 'should map the defined arguments' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end

        describe 'with full values' do
          let(:values) { [true, 'checkerboard'] }
          let(:expected) do
            super().merge(background: 'checkerboard', transparency: true)
          end

          it 'should map the defined arguments' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end

        describe 'with variadic values' do
          let(:values) { ['small', 'medium', 'large', true, 'checkerboard'] }
          let(:expected) do
            super().merge(
              background:   'checkerboard',
              sizes:        values[0..2],
              transparency: true
            )
          end

          it 'should map extra arguments to the variadic parameter' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end
      end

      describe 'with arguments before the variadic argument' do
        let(:expected) { super().merge(color: nil, shape: 'circle', sizes: []) }

        before(:example) do
          described_class.argument  :color, required: true, type: :integer
          described_class.argument  :shape, default:  :circle
          described_class.arguments :sizes
        end

        describe 'with no values' do
          let(:error_message) do
            'invalid value for argument :color - expected an instance of ' \
              'Integer, received nil'
          end

          it 'should raise an exception' do
            expect { described_class.resolve_arguments }
              .to raise_error(
                Cuprum::Cli::Arguments::InvalidArgumentError,
                error_message
              )
          end
        end

        describe 'with partial values' do
          let(:values)   { [0xff3366] }
          let(:expected) { super().merge(color: values[0]) }

          it 'should map the defined arguments' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end

        describe 'with full values' do
          let(:values) { [0xff3366, 'triangle'] }
          let(:expected) do
            super().merge(color: values[0], shape: values[1])
          end

          it 'should map the defined arguments' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end

        describe 'with variadic values' do
          let(:values) { [0xff3366, 'triangle', 'small', 'medium', 'large'] }
          let(:expected) do
            super().merge(
              color: values[0],
              shape: values[1],
              sizes: values[2..4]
            )
          end

          it 'should map extra arguments to the variadic parameter' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end
      end

      describe 'with arguments before and after the variadic argument' do
        let(:expected) do
          super().merge(
            color:        0x0,
            shape:        'circle',
            sizes:        [],
            transparency: false
          )
        end

        before(:example) do
          described_class.argument  :color, default:  0x0, type: :integer
          described_class.argument  :shape, default:  :circle
          described_class.arguments :sizes
          described_class.argument  :transparency, type: :boolean
        end

        describe 'with no values' do
          it 'should map the defined arguments' do
            expect(described_class.resolve_arguments).to be == expected
          end
        end

        describe 'with partial values' do
          let(:values)   { [0xff3366] }
          let(:expected) { super().merge(color: values[0]) }

          it 'should map the defined arguments' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end

        describe 'with full values' do
          let(:values) { [0xff3366, 'triangle', true] }
          let(:expected) do
            super().merge(
              color:        values[0],
              shape:        values[1],
              transparency: true
            )
          end

          it 'should map the defined arguments' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end

        describe 'with variadic values' do
          let(:values) do
            [0xff3366, 'triangle', 'small', 'medium', 'large', true]
          end
          let(:expected) do
            super().merge(
              color:        values[0],
              shape:        values[1],
              sizes:        values[2..4],
              transparency: true
            )
          end

          it 'should map extra arguments to the variadic parameter' do
            expect(described_class.resolve_arguments(*values)).to be == expected
          end
        end
      end
    end
  end
end
