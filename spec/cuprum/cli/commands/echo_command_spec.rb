# frozen_string_literal: true

require 'cuprum/cli/commands/echo_command'
require 'cuprum/cli/rspec/deferred/arguments_examples'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Commands::EchoCommand do
  include Cuprum::Cli::RSpec::Deferred::ArgumentsExamples
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:command) { described_class.new(file_system:, standard_io:) }

  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new }
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }

  include_deferred 'should define argument', 0, :args, variadic: true

  include_deferred 'should define option', :format, type: String, default: nil
  include_deferred 'should define option', :out,    type: String, default: nil

  describe '#call' do
    it { expect(command).to be_callable }

    describe 'with no parameters' do
      let(:expected) do
        <<~OUTPUT
          Cuprum::Cli::Commands::EchoCommand called with no parameters.
        OUTPUT
      end

      it { expect(command.call).to be_a_passing_result.with_value(nil) }

      it 'should write the parameters to STDOUT' do
        command.call

        expect(standard_io.output_stream.string).to be == expected
      end
    end

    describe 'with arguments' do
      let(:arguments) { ['foo', 123, 'bar'] }
      let(:expected) do
        <<~OUTPUT
          Cuprum::Cli::Commands::EchoCommand called with parameters:

            Arguments: ["foo", 123, "bar"]
            Options:   {}
        OUTPUT
      end

      it 'should return a passing result' do
        expect(command.call(*arguments)).to be_a_passing_result.with_value(nil)
      end

      it 'should write the parameters to STDOUT' do
        command.call(*arguments)

        expect(standard_io.output_stream.string).to be == expected
      end
    end

    describe 'with format: "json"' do
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

      it 'should return a passing result' do
        expect(command.call(**options)).to be_a_passing_result.with_value(nil)
      end

      it 'should write the parameters to STDOUT' do
        command.call(**options)

        expect(standard_io.output_stream.string).to be == expected
      end

      describe 'with arguments' do
        let(:arguments) { ['foo', 123, 'bar'] }
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

        it 'should write the parameters to STDOUT' do
          command.call(*arguments, **options)

          expect(standard_io.output_stream.string).to be == expected
        end
      end
    end

    describe 'with out: filename' do
      let(:filename) { 'tmp/echo.txt' }
      let(:options)  { { out: filename } }
      let(:expected) do
        <<~OUTPUT
          Cuprum::Cli::Commands::EchoCommand called with parameters:

            Arguments: []
            Options:   { out: #{filename.inspect} }
        OUTPUT
      end

      it 'should return a passing result' do
        expect(command.call(**options)).to be_a_passing_result.with_value(nil)
      end

      it 'should write the parameters to the output file',
        :aggregate_failures \
      do
        expect { command.call(**options) }.to(
          change { file_system.file?(filename) }.to(be true)
        )

        expect(file_system.read(filename)).to be == expected
      end

      describe 'with arguments' do
        let(:arguments) { ['foo', 123, 'bar'] }
        let(:expected) do
          <<~OUTPUT
            Cuprum::Cli::Commands::EchoCommand called with parameters:

              Arguments: ["foo", 123, "bar"]
              Options:   { out: #{filename.inspect} }
          OUTPUT
        end

        it 'should write the parameters to the output file',
          :aggregate_failures \
        do
          expect { command.call(*arguments, **options) }.to(
            change { file_system.file?(filename) }.to(be true)
          )

          expect(file_system.read(filename)).to be == expected
        end
      end
    end
  end
end
