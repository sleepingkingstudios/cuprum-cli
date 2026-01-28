# frozen_string_literal: true

require 'cuprum/cli/dependencies/standard_io/helpers'
require 'cuprum/cli/dependencies/standard_io/mock'

RSpec.describe Cuprum::Cli::Dependencies::StandardIo::Helpers do
  subject(:command) { Spec::Command.new(mock_io) }

  let(:mock_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }

  example_class 'Spec::Command' do |klass|
    klass.include Cuprum::Cli::Dependencies::StandardIo::Helpers # rubocop:disable RSpec/DescribedClass

    klass.define_method :initialize do |standard_io|
      @standard_io = standard_io
    end

    klass.attr_reader :standard_io
  end

  describe '#ask' do
    it 'should define the method' do
      expect(command)
        .to respond_to(:ask)
        .with(0..1).arguments
        .and_keywords(:caret, :format, :strip)
        .and_any_keywords
    end

    it { expect(command.ask).to be nil }

    it 'should append the caret to the output stream' do
      command.ask

      expect(mock_io.output_stream.string).to be == '> '
    end

    context 'when the input stream has unread data' do
      let(:raw_input) { "Greetings, programs!\n" }

      before(:example) do
        mock_io.class.append_for_read(raw_input, io: mock_io.input_stream)
      end

      it { expect(command.ask).to be == raw_input.strip }
    end

    describe 'with caret: false' do
      it 'should not append to the output stream' do
        command.ask(caret: false)

        expect(mock_io.output_stream.string).to be == ''
      end
    end

    describe 'with format: :boolean' do
      let(:format) { :boolean }

      it { expect(command.ask(format:)).to be nil }

      context 'when the input is an invalid String' do
        invalid_strings = [
          'Alan Bradley',
          'YE',
          'yess',
          'affirmative',
          'negative'
        ]

        invalid_strings.each do |invalid_string|
          context "with #{invalid_string.inspect}" do
            let(:raw_input) { "#{invalid_string}\n" }

            before(:example) do
              mock_io.class.append_for_read(raw_input, io: mock_io.input_stream)
            end

            it { expect(command.ask(format:)).to be nil }
          end
        end
      end

      context 'when the input is a falsy string' do
        falsy_strings = %w[
          F
          FALSE
          False
          f
          false
          NO
          No
          no
          N
          n
        ]

        falsy_strings.each do |falsy_string|
          context "with #{falsy_string.inspect}" do
            let(:raw_input) { "#{falsy_string}\n" }

            before(:example) do
              mock_io.class.append_for_read(raw_input, io: mock_io.input_stream)
            end

            it { expect(command.ask(format:)).to be false }
          end
        end
      end

      context 'when the input is a truthy string' do
        truthy_strings = %w[
          T
          TRUE
          True
          t
          true
          Y
          YES
          Yes
          y
          yes
        ]

        truthy_strings.each do |truthy_string|
          context "with #{truthy_string.inspect}" do
            let(:raw_input) { "#{truthy_string}\n" }

            before(:example) do
              mock_io.class.append_for_read(raw_input, io: mock_io.input_stream)
            end

            it { expect(command.ask(format:)).to be true }
          end
        end
      end
    end

    describe 'with format: :integer' do
      let(:format) { :integer }

      it { expect(command.ask(format:)).to be nil }

      context 'when the input is an invalid string' do
        invalid_strings = [
          'Alan Bradley',
          'three',
          'threeve',
          '0xff3366',
          '_'
        ]

        invalid_strings.each do |invalid_string|
          context "with #{invalid_string.inspect}" do
            let(:raw_input) { "#{invalid_string}\n" }

            before(:example) do
              mock_io.class.append_for_read(raw_input, io: mock_io.input_stream)
            end

            it { expect(command.ask(format:)).to be nil }
          end
        end
      end

      context 'when the input is an valid string' do
        valid_strings = [
          '0',
          '1',
          '10',
          '1000',
          '1,000',
          '1_000',
          '-1'
        ]

        valid_strings.each do |valid_string|
          context "with #{valid_string.inspect}" do
            let(:raw_input) { "#{valid_string}\n" }
            let(:expected)  { valid_string.gsub(/_|,/, '').to_i }

            before(:example) do
              mock_io.class.append_for_read(raw_input, io: mock_io.input_stream)
            end

            it { expect(command.ask(format:)).to be expected }
          end
        end
      end
    end

    describe 'with format: :string' do
      it { expect(command.ask).to be nil }

      context 'when the input is a non-empty String' do
        let(:raw_input) { "Alan Bradley\n" }

        before(:example) do
          mock_io.class.append_for_read(raw_input, io: mock_io.input_stream)
        end

        it { expect(command.ask).to be == raw_input.strip }

        describe 'with strip: false' do
          it { expect(command.ask(strip: false)).to be == raw_input }
        end
      end

      describe 'with strip: false' do
        it { expect(command.ask(strip: false)).to be nil }
      end
    end

    describe 'with prompt: nil' do
      it 'should append the caret to the output stream' do
        command.ask(nil)

        expect(mock_io.output_stream.string).to be == '> '
      end

      describe 'with caret: false' do
        it 'should not append to the output stream' do
          command.ask(nil, caret: false)

          expect(mock_io.output_stream.string).to be == ''
        end
      end
    end

    describe 'with prompt: an Object' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(:instance_of, as: 'prompt', expected: String)
      end

      it 'should raise an exception' do
        expect { command.ask Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with prompt: an empty String' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(:presence, as: 'prompt')
      end

      it 'should raise an exception' do
        expect { command.ask '' }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with prompt: a non-empty String' do
      let(:prompt) { 'Pull the lever?' }

      it 'should append the prompt and caret to the output stream' do
        command.ask(prompt)

        expect(mock_io.output_stream.string).to be == "#{prompt}\n> "
      end

      describe 'with caret: false' do
        it 'should append the prompt to the output stream' do
          command.ask(prompt, caret: false)

          expect(mock_io.output_stream.string).to be == "#{prompt}\n"
        end
      end

      describe 'with newline: false' do
        it 'should append the bare prompt to the output stream' do
          command.ask(prompt, newline: false)

          expect(mock_io.output_stream.string).to be == prompt
        end
      end
    end

    describe 'with strip: false' do
      it { expect(command.ask(strip: false)).to be nil }

      context 'when the input stream has unread data' do
        let(:raw_input) { "Greetings, programs!\n" }

        before(:example) do
          mock_io.class.append_for_read(raw_input, io: mock_io.input_stream)
        end

        it { expect(command.ask(strip: false)).to be == raw_input }
      end
    end
  end

  describe '#say' do
    it 'should define the method' do
      expect(command)
        .to respond_to(:say)
        .with(1).argument
        .and_keywords(:newline)
        .and_any_keywords
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for(
          :instance_of,
          as:       'message',
          expected: String
        )
      end

      it 'should raise an exception' do
        expect { command.say(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for(
          :instance_of,
          as:       'message',
          expected: String
        )
      end

      it 'should raise an exception' do
        expect { command.say(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      it 'should append a newline to the output stream' do
        command.say('')

        expect(mock_io.output_stream.string).to be == "\n"
      end

      describe 'with newline: false' do
        it 'should not append to the output stream' do
          command.say('', newline: false)

          expect(mock_io.output_stream.string).to be == ''
        end
      end
    end

    describe 'with a non-empty String' do
      let(:message) { 'Greetings, programs!' }

      it 'should append the message to the output stream with a newline' do
        command.say(message)

        expect(mock_io.output_stream.string).to be == "#{message}\n"
      end

      describe 'with newline: false' do
        it 'should append the message to the output stream' do
          command.say(message, newline: false)

          expect(mock_io.output_stream.string).to be == message
        end
      end
    end

    describe 'with a String ending with a newline' do
      let(:message)  { "Greetings, programs!\n" }

      it 'should append the message to the output stream' do
        command.say(message)

        expect(mock_io.output_stream.string).to be == message
      end

      describe 'with newline: false' do
        it 'should append the message to the output stream' do
          command.say(message, newline: false)

          expect(mock_io.output_stream.string).to be == message
        end
      end
    end

    describe 'with a multi-line String' do
      let(:message) do
        <<~MESSAGE.strip
          Greetings, starfighters!

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan Armada!
        MESSAGE
      end

      it 'should append the message to the output stream with a newline' do
        command.say(message)

        expect(mock_io.output_stream.string).to be == "#{message}\n"
      end

      describe 'with newline: false' do
        it 'should append the message to the output stream' do
          command.say(message, newline: false)

          expect(mock_io.output_stream.string).to be == message
        end
      end
    end

    describe 'with additional options' do
      let(:message) { 'Greetings, programs!' }
      let(:options) { { quiet: true, verbose: false, strikethrough: '-' } }

      it 'should append the message to the output stream with a newline' do
        command.say(message)

        expect(mock_io.output_stream.string).to be == "#{message}\n"
      end
    end
  end

  describe '#warn' do
    it 'should define the method' do
      expect(command)
        .to respond_to(:warn)
        .with(1).argument
        .and_keywords(:newline)
        .and_any_keywords
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for(
          :instance_of,
          as:       'message',
          expected: String
        )
      end

      it 'should raise an exception' do
        expect { command.warn(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for(
          :instance_of,
          as:       'message',
          expected: String
        )
      end

      it 'should raise an exception' do
        expect { command.warn(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      it 'should append a newline to the error stream' do
        command.warn('')

        expect(mock_io.error_stream.string).to be == "\n"
      end

      describe 'with newline: false' do
        it 'should not append to the error stream' do
          command.warn('', newline: false)

          expect(mock_io.error_stream.string).to be == ''
        end
      end
    end

    describe 'with a non-empty String' do
      let(:message) { 'Greetings, programs!' }

      it 'should append the message to the error stream with a newline' do
        command.warn(message)

        expect(mock_io.error_stream.string).to be == "#{message}\n"
      end

      describe 'with newline: false' do
        it 'should append the message to the error stream' do
          command.warn(message, newline: false)

          expect(mock_io.error_stream.string).to be == message
        end
      end
    end

    describe 'with a String ending with a newline' do
      let(:message)  { "Greetings, programs!\n" }

      it 'should append the message to the error stream' do
        command.warn(message)

        expect(mock_io.error_stream.string).to be == message
      end

      describe 'with newline: false' do
        it 'should append the message to the error stream' do
          command.warn(message, newline: false)

          expect(mock_io.error_stream.string).to be == message
        end
      end
    end

    describe 'with a multi-line String' do
      let(:message) do
        <<~MESSAGE.strip
          Greetings, starfighters!

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan Armada!
        MESSAGE
      end

      it 'should append the message to the error stream with a newline' do
        command.warn(message)

        expect(mock_io.error_stream.string).to be == "#{message}\n"
      end

      describe 'with newline: false' do
        it 'should append the message to the error stream' do
          command.warn(message, newline: false)

          expect(mock_io.error_stream.string).to be == message
        end
      end
    end

    describe 'with additional options' do
      let(:message) { 'Greetings, programs!' }
      let(:options) { { quiet: true, verbose: false, strikethrough: '-' } }

      it 'should append the message to the error stream with a newline' do
        command.warn(message)

        expect(mock_io.error_stream.string).to be == "#{message}\n"
      end
    end
  end
end
