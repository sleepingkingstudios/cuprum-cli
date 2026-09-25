# frozen_string_literal: true

require 'cuprum/cli/files/template'
require 'cuprum/cli/rspec/deferred/templates_examples'

RSpec.describe Cuprum::Cli::Files::Template do
  include Cuprum::Cli::RSpec::Deferred::TemplatesExamples

  subject(:template) { described_class.new(**options) }

  let(:options) { {} }

  describe '.members' do
    let(:expected) { %i[engine] }

    it { expect(described_class.members).to be == expected }
  end

  include_deferred 'should implement the Template interface'

  describe '#call' do
    let(:expected_error) do
      Cuprum::Errors::CommandNotImplemented.new(command: template)
    end

    it 'should return a failing result with a command not implemented error' do
      expect(template.call)
        .to be_a_failing_result
        .with_error(expected_error)
    end

    context 'with a template subclass' do
      subject(:template) { described_class.new(raw_value:, **options) }

      let(:described_class) { Spec::CustomTemplate }
      let(:raw_value)       { 'Greetings, programs!' }
      let(:expected_value)  { raw_value }

      example_constant 'Spec::CustomTemplate' do
        Cuprum::Cli::Files::Template.define(:raw_value) # rubocop:disable RSpec/DescribedClass
      end

      it 'should return a passing result with the rendered template' do
        expect(template.call)
          .to be_a_passing_result
          .with_value(raw_value)
      end

      describe 'with parameters' do
        let(:file_path)  { 'path/to/file.md' }
        let(:parameters) { { file_path: } }

        it 'should return a passing result with the rendered template' do
          expect(template.call(**parameters))
            .to be_a_passing_result
            .with_value(raw_value)
        end
      end

      include_deferred 'should apply the configured engine'

      context 'when the template subclass defines a template name' do
        let(:template_name) { 'spec.example_template' }

        before(:example) do
          name = template_name

          Spec::CustomTemplate.class_exec do
            define_method :template_name do
              name
            end
          end
        end

        include_deferred 'should apply the configured engine'
      end
    end
  end

  describe '#raw_value' do
    let(:expected_error) do
      Cuprum::Errors::CommandNotImplemented.new(command: template)
    end

    it 'should return a failing result' do
      expect(template.send(:raw_value))
        .to be_a_failing_result
        .with_error(expected_error)
    end
  end
end
