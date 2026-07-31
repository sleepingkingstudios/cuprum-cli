# frozen_string_literal: true

require 'cuprum/cli/files/engines/render_template'

RSpec.describe Cuprum::Cli::Files::Engines::RenderTemplate do
  subject(:command) do
    described_class.new(file_system:)
  end

  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new(files:) }
  let(:files)       { { 'templates' => {} } }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  describe '#call' do
    deferred_examples 'should generate the plain text template' do
      let(:raw_template) do
        <<~MARKDOWN
          # Greetings, Starfighter

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan armada!
        MARKDOWN
      end
      let(:expected_value) { raw_template }

      it 'should return a passing result' do
        expect(call_command)
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end

    deferred_examples 'should generate the ERB template' do
      let(:engine) { Cuprum::Cli::Files::Engines::ERB }
      let(:raw_template) do
        <<~MARKDOWN
          # <%= greeting %>

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan armada!
        MARKDOWN
      end

      describe 'with invalid parameters' do
        let(:expected_error) do
          Cuprum::Cli::Errors::Files::MissingParameter.new(
            message:        'unable to render ERB template',
            parameter_name: :greeting
          )
        end

        it 'should return a failing result' do
          expect(call_command)
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'with valid parameters' do
        let(:parameters) { super().merge(greeting: 'Greetings, Programs!') }
        let(:expected_value) do
          <<~MARKDOWN
            # Greetings, Programs!

            You have been recruited by the Star League to defend the frontier
            against Xur and the Ko-Dan armada!
          MARKDOWN
        end

        it 'should return a passing result' do
          expect(call_command)
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end

    deferred_examples 'should handle invalid engines' do
      let(:engine) { 'jinja2' }
      let(:raw_template) do
        <<~MARKDOWN
          # Greetings, Starfighter

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan armada!
        MARKDOWN
      end
      let(:expected_error) do
        details = "unknown template engine #{engine.inspect}"

        Cuprum::Cli::Errors::Files::TemplateError.new(
          details:,
          message: "unable to render template - #{details}"
        )
      end

      it 'should return a failing result' do
        expect(call_command)
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    let(:engine)     { nil }
    let(:parameters) { {} }

    define_method(:call_command) do
      command.call(template, **parameters)
    end

    it 'should define the method' do
      expect(command)
        .to be_callable
        .with(1).argument
        .and_any_keywords
    end

    describe 'with a file template' do
      let(:file_path) { 'templates/docs.md' }
      let(:template) do
        Cuprum::Cli::Files::Templates::FileTemplate.new(engine:, file_path:)
      end

      context 'when the template file does not exist' do
        let(:expected_error) do
          Cuprum::Cli::Errors::Files::MissingTemplate.new(
            message:       'unable to generate file',
            template_path: template.file_path
          )
        end

        it 'should return a failing result' do
          expect(call_command)
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the template file exists' do
        before(:example) do
          file_system.write(file_path, raw_template)
        end

        describe 'with a plain text template' do
          include_deferred 'should generate the plain text template'
        end

        describe 'with an ERB template' do
          let(:file_path) { 'templates/docs.md.erb' }

          include_deferred 'should generate the ERB template'
        end

        describe 'with a template with invalid engine' do
          include_deferred 'should handle invalid engines'
        end
      end
    end

    describe 'with a string template' do
      let(:template) do
        Cuprum::Cli::Files::Templates::StringTemplate
          .new(engine:, raw_template:)
      end

      describe 'with a plain text template' do
        include_deferred 'should generate the plain text template'
      end

      describe 'with an ERB template' do
        include_deferred 'should generate the ERB template'
      end
    end
  end
end
