# frozen_string_literal: true

require 'stringio'

require 'cuprum/cli/dependencies/standard_io'

RSpec.describe Cuprum::Cli::Dependencies::StandardIo do
  subject(:standard_io) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:input, :error, :output)
    end
  end

  describe '#ask' do
    let(:raw_input) { "\n" }

    before(:example) do
      allow($stdout).to receive(:print)
      allow($stdin).to receive(:gets).and_return(raw_input)
    end

    it 'should define the method' do
      expect(standard_io)
        .to respond_to(:ask)
        .with(0..1).arguments
        .and_keywords(:caret, :format, :strip)
        .and_any_keywords
    end

    it { expect(standard_io.ask).to be nil }

    it { expect { standard_io.ask }.to output('> ').to_stdout }

    context 'when the input is a non-empty String' do
      let(:raw_input) { "Alan Bradley\n" }

      it { expect(standard_io.ask).to be == raw_input.strip }

      describe 'with strip: false' do
        it { expect(standard_io.ask(strip: false)).to be == raw_input }
      end
    end

    describe 'with caret: false' do
      it { expect { standard_io.ask(caret: false) }.not_to output.to_stdout }
    end

    describe 'with format: :boolean' do
      let(:format) { :boolean }

      it { expect(standard_io.ask(format:)).to be nil }

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

            it { expect(standard_io.ask(format:)).to be nil }
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

            it { expect(standard_io.ask(format:)).to be false }
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

            it { expect(standard_io.ask(format:)).to be true }
          end
        end
      end
    end

    describe 'with format: :integer' do
      let(:format) { :integer }

      it { expect(standard_io.ask(format:)).to be nil }

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

            it { expect(standard_io.ask(format:)).to be nil }
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

            it { expect(standard_io.ask(format:)).to be expected }
          end
        end
      end
    end

    describe 'with format: :string' do
      it { expect(standard_io.ask).to be nil }

      context 'when the input is a non-empty String' do
        let(:raw_input) { "Alan Bradley\n" }

        it { expect(standard_io.ask).to be == raw_input.strip }

        describe 'with strip: false' do
          it { expect(standard_io.ask(strip: false)).to be == raw_input }
        end
      end

      describe 'with strip: false' do
        it { expect(standard_io.ask(strip: false)).to be == raw_input }
      end
    end

    describe 'with prompt: nil' do
      it { expect { standard_io.ask }.to output('> ').to_stdout }

      describe 'with caret: false' do
        it { expect { standard_io.ask(caret: false) }.not_to output.to_stdout }
      end
    end

    describe 'with prompt: an Object' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(:instance_of, as: 'prompt', expected: String)
      end

      it 'should raise an exception' do
        expect { standard_io.ask Object.new.freeze }
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
        expect { standard_io.ask '' }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with prompt: a non-empty String' do
      let(:prompt)   { 'Pull the lever?' }
      let(:expected) { "#{prompt}\n> " }

      it { expect { standard_io.ask(prompt) }.to output(expected).to_stdout }

      describe 'with caret: false' do
        let(:expected) { "#{prompt}\n" }

        it 'should not append the caret' do
          expect { standard_io.ask(prompt, caret: false) }
            .to output(expected)
            .to_stdout
        end
      end

      describe 'with newline: false' do
        it 'should not append the caret' do
          expect { standard_io.ask(prompt, newline: false) }
            .to output(prompt)
            .to_stdout
        end
      end
    end

    describe 'with strip: false' do
      it { expect(standard_io.ask(strip: false)).to be == raw_input }
    end

    context 'when initialized with input: value' do
      let(:input_stream)        { StringIO.new(raw_input) }
      let(:constructor_options) { super().merge(input: input_stream) }

      before(:example) do
        allow($stdin).to receive(:gets).and_call_original
      end

      it { expect(standard_io.ask).to be nil }

      context 'when the input is a non-empty String' do
        let(:raw_input) { "Alan Bradley\n" }

        it { expect(standard_io.ask).to be == raw_input.strip }

        describe 'with strip: false' do
          it { expect(standard_io.ask(strip: false)).to be == raw_input }
        end
      end
    end

    context 'when initialized with output: value' do
      let(:output_stream)       { StringIO.new }
      let(:constructor_options) { super().merge(output: output_stream) }

      it { expect { standard_io.ask }.not_to output.to_stdout }

      it 'should append the prompt to the output stream' do
        standard_io.ask

        expect(output_stream.string).to be == '> '
      end

      describe 'with prompt: a non-empty String' do
        let(:prompt)   { 'Pull the lever?' }
        let(:expected) { "#{prompt}\n> " }

        it { expect { standard_io.ask(prompt) }.not_to output.to_stdout }

        it 'should append the prompt to the output stream' do
          standard_io.ask(prompt)

          expect(output_stream.string).to be == expected
        end
      end
    end
  end

  describe '#error' do
    include_examples 'should define private reader', :error, -> { $stderr }

    context 'when initialized with error: value' do
      let(:error_stream)        { StringIO.new }
      let(:constructor_options) { super().merge(error: error_stream) }

      it { expect(standard_io.send(:error)).to be error_stream }
    end
  end

  describe '#input' do
    include_examples 'should define private reader', :input, -> { $stdin }

    context 'when initialized with input: value' do
      let(:input_stream)        { StringIO.new }
      let(:constructor_options) { super().merge(input: input_stream) }

      it { expect(standard_io.send(:input)).to be input_stream }
    end
  end

  describe '#output' do
    include_examples 'should define private reader', :output, -> { $stdout }

    context 'when initialized with output: value' do
      let(:output_stream)       { StringIO.new }
      let(:constructor_options) { super().merge(output: output_stream) }

      it { expect(standard_io.send(:output)).to be output_stream }
    end
  end

  describe '#say' do
    it 'should define the method' do
      expect(standard_io)
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
        expect { standard_io.say(nil) }
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
        expect { standard_io.say(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      it { expect { standard_io.say('') }.to output("\n").to_stdout }

      describe 'with newline: false' do
        let(:newline) { false }

        it { expect { standard_io.say('', newline:) }.not_to output.to_stdout }
      end
    end

    describe 'with a non-empty String' do
      let(:message)  { 'Greetings, programs!' }
      let(:expected) { "#{message}\n" }

      it { expect { standard_io.say(message) }.to output(expected).to_stdout }

      describe 'with newline: false' do
        let(:newline) { false }

        it 'should not append a newline' do
          expect { standard_io.say(message, newline:) }
            .to output(message)
            .to_stdout
        end
      end
    end

    describe 'with a String ending with a newline' do
      let(:message)  { "Greetings, programs!\n" }

      it 'should not append a newline' do
        expect { standard_io.say(message) }
          .to output(message)
          .to_stdout
      end

      describe 'with newline: false' do
        let(:newline) { false }

        it 'should not append a newline' do
          expect { standard_io.say(message, newline:) }
            .to output(message)
            .to_stdout
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
      let(:expected) { "#{message}\n" }

      it { expect { standard_io.say(message) }.to output(expected).to_stdout }

      describe 'with newline: false' do
        let(:newline) { false }

        it 'should not append a newline' do
          expect { standard_io.say(message, newline:) }
            .to output(message)
            .to_stdout
        end
      end
    end

    describe 'with additional options' do
      let(:message)  { 'Greetings, programs!' }
      let(:options)  { { quiet: true, verbose: false, strikethrough: '-' } }
      let(:expected) { "#{message}\n" }

      it 'should print the string' do
        expect { standard_io.say(message, **options) }
          .to output(expected).to_stdout
      end
    end

    context 'when initialized with output: value' do
      let(:output_stream)       { StringIO.new }
      let(:constructor_options) { super().merge(output: output_stream) }

      describe 'with an empty String' do
        let(:expected) { "\n" }

        it { expect { standard_io.say('') }.not_to output.to_stdout }

        it 'should write to the output stream' do
          standard_io.say('')

          expect(output_stream.string).to be == expected
        end
      end

      describe 'with a non-empty String' do
        let(:message)  { 'Greetings, programs!' }
        let(:expected) { "#{message}\n" }

        it { expect { standard_io.say(message) }.not_to output.to_stdout }

        it 'should write to the output stream' do
          standard_io.say(message)

          expect(output_stream.string).to be == expected
        end
      end
    end
  end

  describe '#warn' do
    it 'should define the method' do
      expect(standard_io)
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
        expect { standard_io.warn(nil) }
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
        expect { standard_io.warn(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      it { expect { standard_io.warn('') }.to output("\n").to_stderr }

      describe 'with newline: false' do
        let(:newline) { false }

        it { expect { standard_io.warn('', newline:) }.not_to output.to_stderr }
      end
    end

    describe 'with a non-empty String' do
      let(:message)  { 'Greetings, programs!' }
      let(:expected) { "#{message}\n" }

      it { expect { standard_io.warn(message) }.to output(expected).to_stderr }

      describe 'with newline: false' do
        let(:newline) { false }

        it 'should not append a newline' do
          expect { standard_io.warn(message, newline:) }
            .to output(message)
            .to_stderr
        end
      end
    end

    describe 'with a String ending with a newline' do
      let(:message)  { "Greetings, programs!\n" }

      it 'should not append a newline' do
        expect { standard_io.warn(message) }
          .to output(message)
          .to_stderr
      end

      describe 'with newline: false' do
        let(:newline) { false }

        it 'should not append a newline' do
          expect { standard_io.warn(message, newline:) }
            .to output(message)
            .to_stderr
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
      let(:expected) { "#{message}\n" }

      it { expect { standard_io.warn(message) }.to output(expected).to_stderr }

      describe 'with newline: false' do
        let(:newline) { false }

        it 'should not append a newline' do
          expect { standard_io.warn(message, newline:) }
            .to output(message)
            .to_stderr
        end
      end
    end

    context 'when initialized with error: value' do
      let(:error_stream)        { StringIO.new }
      let(:constructor_options) { super().merge(error: error_stream) }

      describe 'with an empty String' do
        let(:expected) { "\n" }

        it { expect { standard_io.warn('') }.not_to output.to_stderr }

        it 'should write to the error stream' do
          standard_io.warn('')

          expect(error_stream.string).to be == expected
        end
      end

      describe 'with a non-empty String' do
        let(:message)  { 'Greetings, programs!' }
        let(:expected) { "#{message}\n" }

        it { expect { standard_io.warn(message) }.not_to output.to_stderr }

        it 'should write to the error stream' do
          standard_io.warn(message)

          expect(error_stream.string).to be == expected
        end
      end
    end
  end
end
