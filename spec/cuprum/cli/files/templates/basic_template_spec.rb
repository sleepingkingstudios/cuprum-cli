# frozen_string_literal: true

require 'cuprum/cli/files/templates/basic_template'
require 'cuprum/cli/rspec/deferred/templates_examples'

RSpec.describe Cuprum::Cli::Files::Templates::BasicTemplate do
  include Cuprum::Cli::RSpec::Deferred::TemplatesExamples

  subject(:template) { described_class.new(**options) }

  let(:options) { {} }

  describe '.members' do
    let(:expected) { %i[engine] }

    it { expect(described_class.members).to be == expected }
  end

  include_deferred 'should implement the Template interface'

  describe '#call' do
    describe 'with no parameters' do
      let(:expected_error) do
        failures = [
          tools.assertions.error_message_for(:presence, as: 'contents'),
          tools.assertions.error_message_for(
            :instance_of,
            as:       'contents',
            expected: String
          )
        ]

        Cuprum::Errors::InvalidParameters.new(
          command_class: described_class,
          failures:
        )
      end

      it 'should return a failing result with an invalid parameters error' do
        expect(template.call)
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with contents: nil' do
      let(:parameters) { { contents: nil } }
      let(:expected_error) do
        failures = [
          tools.assertions.error_message_for(:presence, as: 'contents'),
          tools.assertions.error_message_for(
            :instance_of,
            as:       'contents',
            expected: String
          )
        ]

        Cuprum::Errors::InvalidParameters.new(
          command_class: described_class,
          failures:
        )
      end

      it 'should return a failing result with an invalid parameters error' do
        expect(template.call(**parameters))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with contents: an Object' do
      let(:parameters) { { contents: Object.new.freeze } }
      let(:expected_error) do
        failures = [
          tools.assertions.error_message_for(
            :instance_of,
            as:       'contents',
            expected: String
          )
        ]

        Cuprum::Errors::InvalidParameters.new(
          command_class: described_class,
          failures:
        )
      end

      it 'should return a failing result with an invalid parameters error' do
        expect(template.call(**parameters))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with contents: an empty String' do
      let(:parameters) { { contents: '' } }
      let(:expected_error) do
        failures = [
          tools.assertions.error_message_for(:presence, as: 'contents')
        ]

        Cuprum::Errors::InvalidParameters.new(
          command_class: described_class,
          failures:
        )
      end

      it 'should return a failing result with an invalid parameters error' do
        expect(template.call(**parameters))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with contents: a non-empty String' do
      let(:raw_value)  { 'Greetings, programs!' }
      let(:contents)   { raw_value }
      let(:parameters) { { contents: } }

      it 'should return a passing result with the rendered template' do
        expect(template.call(**parameters))
          .to be_a_passing_result
          .with_value(raw_value)
      end

      include_deferred 'should apply the configured engine'
    end
  end
end
