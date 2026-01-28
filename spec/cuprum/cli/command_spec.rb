# frozen_string_literal: true

require 'cuprum/cli/command'
require 'cuprum/cli/rspec/deferred/arguments_examples'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Command do
  include Cuprum::Cli::RSpec::Deferred::ArgumentsExamples
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:command) { described_class.new(**constructor_options) }

  deferred_context 'with a command subclass' do
    let(:described_class) { Spec::Command }

    example_class 'Spec::Command', 'Cuprum::Cli::Command'
  end

  let(:constructor_options) { {} }

  describe '::AbstractCommandError' do
    include_examples 'should define constant',
      :AbstractCommandError,
      -> { be_a(Class).and be < StandardError }
  end

  describe '.argument' do
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
    let(:error_message) do
      'unable to define argument :format - Cuprum::Cli::Command is an ' \
        'abstract class'
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:argument)
        .with(1).argument
        .and_keywords(*expected_keywords)
    end

    it 'should raise an exception' do
      expect { described_class.argument(name) }
        .to raise_error described_class::AbstractCommandError, error_message
    end

    wrap_deferred 'with a command subclass' do
      context 'when the argument is defined' do
        before(:example) { described_class.argument(name, **options) }

        include_deferred 'should define argument', 0, :format
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
    end

    describe 'with an argument name' do
      let(:name)    { :formats }
      let(:options) { {} }
      let(:error_message) do
        'unable to define argument :formats - Cuprum::Cli::Command is an ' \
          'abstract class'
      end

      it 'should raise an exception' do
        expect { described_class.argument(name) }
          .to raise_error described_class::AbstractCommandError, error_message
      end

      wrap_deferred 'with a command subclass' do
        context 'when the argument is defined' do
          before(:example) { described_class.arguments(name, **options) }

          include_deferred 'should define argument', 0, :formats, variadic: true
        end
      end
    end
  end

  describe '.dependency' do
    let(:name) { :standard_io }
    let(:expected_keywords) do
      %i[
        as
        memoize
        optional
        predicate
        scope
      ]
    end
    let(:error_message) do
      'unable to add dependency :standard_io - Cuprum::Cli::Command is an ' \
        'abstract class'
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:dependency)
        .with(1).argument
        .and_keywords(*expected_keywords)
    end

    it 'should raise an exception' do
      expect { described_class.dependency(name) }
        .to raise_error described_class::AbstractCommandError, error_message
    end

    wrap_deferred 'with a command subclass' do
      context 'when the dependency is defined' do
        before(:example) { described_class.dependency(name) }

        include_examples 'should define reader',
          :standard_io,
          -> { be_a(Cuprum::Cli::Dependencies::StandardIo) }

        it { expect(command).to respond_to(:ask) }

        context 'when initialized with a dependency' do
          let(:mock_io) do
            Cuprum::Cli::Dependencies::StandardIo::Mock.new
          end
          let(:constructor_options) { super().merge(standard_io: mock_io) }

          it { expect(command.standard_io).to be mock_io }
        end
      end
    end
  end

  describe '.option' do
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
    let(:error_message) do
      'unable to define option :format - Cuprum::Cli::Command is an abstract ' \
        'class'
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:option)
        .with(1).argument
        .and_keywords(*expected_keywords)
    end

    it 'should raise an exception' do
      expect { described_class.option(name, **options) }
        .to raise_error described_class::AbstractCommandError, error_message
    end

    wrap_deferred 'with a command subclass' do
      context 'when the option is defined' do
        before(:example) { described_class.option(name, **options) }

        include_deferred 'should define option', :format
      end
    end
  end

  describe '.plumbum_providers' do
    it 'should include the dependencies provider' do
      expect(described_class.plumbum_providers)
        .to include(Cuprum::Cli::Dependencies.provider)
    end
  end

  describe '#arguments' do
    include_examples 'should define private reader', :arguments, {}
  end

  describe '#call' do
    let(:expected_error) do
      Cuprum::Errors::CommandNotImplemented.new(command:)
    end

    it 'should define the method' do
      expect(command)
        .to be_callable
        .with_unlimited_arguments
        .and_any_keywords
    end

    it 'should return a failing result' do
      expect(command.call)
        .to be_a_failing_result
        .with_error(expected_error)
    end

    wrap_deferred 'with a command subclass' do
      let(:expected_arguments) do
        { color: nil, shape: 'circle' }
      end
      let(:expected_options) do
        { size: 'medium', transparent: false }
      end
      let(:expected_value) do
        { arguments: expected_arguments, options: expected_options }
      end

      before(:example) do
        Spec::Command.class_eval do
          argument :color, type:    :integer
          argument :shape, default: :circle

          option :size,        default: 'medium'
          option :transparent, type:    :boolean

          def process(...)
            super

            { arguments:, options: }
          end
        end
      end

      describe 'with no parameters' do
        it 'should return a passing result' do
          expect(command.call)
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with invalid arguments' do
        let(:arguments) { %w[red] }
        let(:error_message) do
          'invalid value for argument :color - expected an instance of ' \
            'Integer, received "red"'
        end

        it 'should raise an exception' do
          expect { command.call(*arguments) }
            .to raise_error(
              Cuprum::Cli::Arguments::InvalidArgumentError,
              error_message
            )
        end
      end

      describe 'with valid arguments' do
        let(:arguments)          { [0xff3366] }
        let(:expected_arguments) { super().merge(color: arguments[0]) }

        it 'should return a passing result' do
          expect(command.call(*arguments))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with invalid options' do
        let(:options) { { transparent: 'yes' } }
        let(:error_message) do
          'invalid value for option :transparent - expected true or false, ' \
            'received "yes"'
        end

        it 'should raise an exception' do
          expect { command.call(**options) }
            .to raise_error(
              Cuprum::Cli::Options::InvalidOptionError,
              error_message
            )
        end
      end

      describe 'with valid options' do
        let(:options)          { { size: 'large' } }
        let(:expected_options) { super().merge(size: options[:size]) }

        it 'should return a passing result' do
          expect(command.call(**options))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with valid options and arguments' do
        let(:arguments)          { [0xff3366] }
        let(:expected_arguments) { super().merge(color: arguments[0]) }
        let(:options)            { { size: 'large' } }
        let(:expected_options)   { super().merge(size: options[:size]) }

        it 'should return a passing result' do
          expect(command.call(*arguments, **options))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with resolved options and arguments' do
        let(:resolved_arguments) { { color: 'red' } }
        let(:resolved_options)   { { transparent: 'yes' } }
        let(:expected_value) do
          {
            arguments: resolved_arguments,
            options:   resolved_options
          }
        end

        it 'should return a passing result' do
          expect(command.call(resolved_arguments:, resolved_options:))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end
  end

  describe '#options' do
    include_examples 'should define private reader', :options, {}
  end

  describe '#tools' do
    let(:expected) { SleepingKingStudios::Tools::Toolbelt.instance }

    include_examples 'should define private reader', :tools

    it { expect(command.send(:tools).equal?(expected)).to be true }
  end
end
