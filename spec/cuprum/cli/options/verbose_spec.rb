# frozen_string_literal: true

require 'cuprum/cli/command'
require 'cuprum/cli/dependencies/standard_io/mock'
require 'cuprum/cli/options/verbose'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Options::Verbose do
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:command) { described_class.new(standard_io: mock_io) }

  let(:described_class) { Spec::ExampleCommand }
  let(:mock_io)         { Cuprum::Cli::Dependencies::StandardIo::Mock.new }

  example_class 'Spec::ExampleCommand', Cuprum::Cli::Command do |klass|
    klass.include Cuprum::Cli::Dependencies::StandardIo::Helpers
    klass.include Cuprum::Cli::Options::Verbose # rubocop:disable RSpec/DescribedClass

    klass.dependency :standard_io
    klass.option     :opts, type: :hash
  end

  include_deferred 'should define option',
    :verbose,
    type:        :boolean,
    aliases:     %w[v],
    default:     false,
    description: 'Enables optional console outputs.'

  describe '#say' do
    let(:expected_message) { "Greetings, programs!\n" }

    before(:example) do
      described_class.class_eval do
        # @todo [RUBY_VERSION <= '3.3'] remove || {} fallbacks.
        define_method(:process) { say('Greetings, programs!', **(opts || {})) }
      end
    end

    it 'should define the method' do
      expect(command)
        .to respond_to(:say)
        .with(1).argument
        .and_keywords(:newline, :verbose)
        .and_any_keywords
    end

    context 'when called with verbose: nil' do
      it 'should output the message to the output stream' do
        command.call

        expect(mock_io.output_stream.string).to be == expected_message
      end

      describe 'with verbose: false' do
        let(:opts) { { verbose: false } }

        it 'should output the message to the output stream' do
          command.call(opts:)

          expect(mock_io.output_stream.string).to be == expected_message
        end
      end

      describe 'with verbose: true' do
        let(:opts) { { verbose: true } }

        it 'should not output the message to the output stream' do
          command.call(opts:)

          expect(mock_io.output_stream.string).to be == ''
        end
      end
    end

    context 'when called with verbose: false' do
      it 'should output the message to the output stream' do
        command.call(verbose: false)

        expect(mock_io.output_stream.string).to be == expected_message
      end

      describe 'with verbose: false' do
        let(:opts) { { verbose: false } }

        it 'should output the message to the output stream' do
          command.call(verbose: false, opts:)

          expect(mock_io.output_stream.string).to be == expected_message
        end
      end

      describe 'with verbose: true' do
        let(:opts) { { verbose: true } }

        it 'should not output the message to the output stream' do
          command.call(verbose: false, opts:)

          expect(mock_io.output_stream.string).to be == ''
        end
      end
    end

    context 'when called with verbose: true' do
      it 'should output the message to the output stream' do
        command.call(verbose: true)

        expect(mock_io.output_stream.string).to be == expected_message
      end

      describe 'with verbose: false' do
        let(:opts) { { verbose: false } }

        it 'should output the message to the output stream' do
          command.call(verbose: true, opts:)

          expect(mock_io.output_stream.string).to be == expected_message
        end
      end

      describe 'with verbose: true' do
        let(:opts) { { verbose: true } }

        it 'should output the message to the output stream' do
          command.call(verbose: true, opts:)

          expect(mock_io.output_stream.string).to be == expected_message
        end
      end
    end
  end
end
