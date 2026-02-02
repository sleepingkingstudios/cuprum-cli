# frozen_string_literal: true

require 'cuprum/cli/command'
require 'cuprum/cli/dependencies/standard_io/mock'
require 'cuprum/cli/options/quiet'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Options::Quiet do
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:command) { described_class.new(standard_io: mock_io) }

  let(:described_class) { Spec::ExampleCommand }
  let(:mock_io)         { Cuprum::Cli::Dependencies::StandardIo::Mock.new }

  example_class 'Spec::ExampleCommand', Cuprum::Cli::Command do |klass|
    klass.dependency :standard_io

    klass.include Cuprum::Cli::Dependencies::StandardIo::Helpers
    klass.include Cuprum::Cli::Options::Quiet # rubocop:disable RSpec/DescribedClass
  end

  include_deferred 'should define option',
    :quiet,
    type:        :boolean,
    aliases:     %w[q],
    default:     false,
    description: 'Silences non-essential console outputs.'

  describe '#say' do
    let(:expected_message) { "Greetings, programs!\n" }

    before(:example) do
      described_class.class_eval do
        define_method(:process) { say('Greetings, programs!') }
      end
    end

    it 'should define the method' do
      expect(command)
        .to respond_to(:say)
        .with(1).argument
        .and_keywords(:newline, :quiet)
        .and_any_keywords
    end

    context 'when called with quiet: nil' do
      it 'should output the message to the output stream' do
        command.call

        expect(mock_io.output_stream.string).to be == expected_message
      end
    end

    context 'when called with quiet: false' do
      it 'should output the message to the output stream' do
        command.call(quiet: false)

        expect(mock_io.output_stream.string).to be == expected_message
      end
    end

    context 'when called with quiet: true' do
      it 'should not output the message to the output stream' do
        command.call(quiet: true)

        expect(mock_io.output_stream.string).to be == ''
      end
    end
  end
end
