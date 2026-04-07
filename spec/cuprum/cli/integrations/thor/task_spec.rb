# frozen_string_literal: true

require 'cuprum/cli/commands/echo_command'
require 'cuprum/cli/dependencies/standard_io/mock'
require 'cuprum/cli/integrations/thor/task'

RSpec.describe Cuprum::Cli::Integrations::Thor::Task, integration: :thor do
  subject(:task) do
    described_class
      .new(command_class, [], options, config, command_dependencies:)
  end

  let(:command_class)        { Cuprum::Cli::Commands::EchoCommand }
  let(:mock_io)              { Cuprum::Cli::Dependencies::StandardIo::Mock.new }
  let(:command_dependencies) { { standard_io: mock_io } }
  let(:options)              { {} }
  let(:config)               { {} }

  describe '.exit_on_failure?' do
    it { expect(described_class.exit_on_failure?).to be true }
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1..4).arguments
    end
  end

  describe '.subclass' do
    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:subclass)
        .with_unlimited_arguments
        .and_any_keywords
        .and_a_block
    end

    describe 'with a command class' do
      subject(:task) { described_class.new([], options, config) }

      let(:described_class) { super().subclass(command_class) }

      it { expect(task.command_class).to be command_class }
    end
  end

  describe '#args' do
    it { expect(task.args).to be == [] }

    context 'when the task is called with arguments' do
      let(:arguments) { %w[foo bar baz] }

      it { expect(task.args).to be == [] }
    end
  end

  describe '#call_command' do
    it { expect(task).to respond_to(:call_command).with(0).arguments }

    describe 'with no parameters' do
      let(:expected) do
        "#{command_class} called with no parameters.\n"
      end

      it 'should call the command' do
        task.call_command

        expect(mock_io.output_stream.string).to be == expected
      end

      context 'when the command returns a failing result' do
        let(:command_class) { Spec::FailingCommand }

        example_class 'Spec::FailingCommand', Cuprum::Cli::Command do |klass|
          klass.dependency :standard_io

          klass.define_method :process do
            standard_io.write_output "#{self.class} called with no parameters."

            Cuprum::Result.new(status: :failure)
          end
        end

        before(:example) { allow(task).to receive(:exit_proxy) } # rubocop:disable RSpec/SubjectStub

        it 'should call the command' do
          task.call_command

          expect(mock_io.output_stream.string).to be == expected
        end

        it 'should exit with a non-zero status code' do
          task.call_command

          expect(task).to have_received(:exit_proxy).with(false) # rubocop:disable RSpec/SubjectStub
        end
      end

      context 'when the command returns a failing result with an error' do
        let(:command_class) { Spec::FailingCommand }

        example_class 'Spec::FailingCommand', Cuprum::Cli::Command do |klass|
          klass.dependency :standard_io

          klass.define_method :process do
            standard_io.write_output "#{self.class} called with no parameters."

            error = Cuprum::Error.new(message: 'Something went wrong.')

            Cuprum::Result.new(error:)
          end
        end

        before(:example) { allow(task).to receive(:exit_proxy) } # rubocop:disable RSpec/SubjectStub

        it 'should call the command' do
          task.call_command

          expect(mock_io.output_stream.string).to be == expected
        end

        it 'should exit with a non-zero status code' do
          task.call_command

          expect(task) # rubocop:disable RSpec/SubjectStub
            .to have_received(:exit_proxy)
            .with('Something went wrong.')
        end
      end
    end

    context 'when the task is initialized with arguments' do
      let(:arguments) { ['foo', 123, 'bar'] }
      let(:expected) do
        <<~OUTPUT
          #{command_class} called with parameters:

            Arguments: ["foo", 123, "bar"]
            Options:   {}
        OUTPUT
      end

      it 'should call the command' do
        task.call_command(*arguments)

        expect(mock_io.output_stream.string).to be == expected
      end
    end

    context 'when the task is initialized with options' do
      let(:options) { { format: 'json' } }
      let(:expected) do
        <<~JSON
          {
            "arguments": [],
            "options": {
              "format": "json"
            }
          }
        JSON
      end

      it 'should call the command' do
        task.call_command

        expect(mock_io.output_stream.string).to be == expected
      end
    end

    context 'when the task is initialized with arguments and options' do
      let(:arguments) { ['foo', 123, 'bar'] }
      let(:options)   { { format: 'json' } }
      let(:expected) do
        <<~JSON
          {
            "arguments": [
              "foo",
              123,
              "bar"
            ],
            "options": {
              "format": "json"
            }
          }
        JSON
      end

      it 'should call the command' do
        task.call_command(*arguments)

        expect(mock_io.output_stream.string).to be == expected
      end
    end
  end

  describe '#command_class' do
    include_examples 'should define reader',
      :command_class,
      -> { command_class }
  end

  describe '#options' do
    it { expect(task.options).to be == {} }

    context 'when the task is called with options' do
      let(:options) { { 'option' => 'value' } }

      it { expect(task.options).to be == options }
    end
  end
end
