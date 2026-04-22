# frozen_string_literal: true

require 'cuprum/cli/commands/file/render_erb'

RSpec.describe Cuprum::Cli::Commands::File::RenderErb do
  subject(:command) { described_class.new(**options) }

  let(:options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:template_name)
    end
  end

  describe '#call' do
    let(:template)   { '' }
    let(:parameters) { {} }
    let(:expected_value) do
      template
    end

    it { expect(command).to be_callable.with(1).argument.and_any_keywords }

    it 'should return a passing result' do
      expect(command.call(template, **parameters))
        .to be_a_passing_result
        .with_value(expected_value)
    end

    describe 'with extra parameters' do
      let(:parameters) { super().merge(extra_parameter: 'extra value') }

      it 'should return a passing result' do
        expect(command.call(template, **parameters))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end

    describe 'with a non-empty template' do
      let(:template) { 'Greetings, programs!' }

      it 'should return a passing result' do
        expect(command.call(template, **parameters))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      describe 'with extra parameters' do
        let(:parameters) { super().merge(extra_parameter: 'extra value') }

        it 'should return a passing result' do
          expect(command.call(template, **parameters))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end

    describe 'with a parameterized template' do
      let(:template) { '<h1><%= greeting %></h1>' }

      describe 'with a missing parameter' do
        let(:expected_error) do
          Cuprum::Cli::Errors::Files::MissingParameter.new(
            message:        'unable to render ERB template',
            parameter_name: :greeting,
            template_name:  command.template_name
          )
        end

        it 'should return a failing result' do
          expect(command.call(template, **parameters))
            .to be_a_failing_result
            .with_error(expected_error)
        end

        context 'when initialized with template_name: value' do
          let(:template_name) { 'template.html.erb' }
          let(:options)       { super().merge(template_name:) }

          it 'should return a failing result' do
            expect(command.call(template, **parameters))
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end
      end

      describe 'with a parameter of invalid type' do
        let(:template)   { "<h1><%= greetings.join(', ') %></h1>" }
        let(:parameters) { super().merge(greetings: 'Greetings, starfighter!') }
        let(:expected_error) do
          message =
            begin
              ''.join
            rescue NameError => exception
              exception.message
            end

          Cuprum::Cli::Errors::Files::TemplateError.new(
            message:       "unable to render ERB template - #{message}",
            template_name: command.template_name
          )
        end

        it 'should return a failing result' do
          expect(command.call(template, **parameters))
            .to be_a_failing_result
            .with_error(expected_error)
        end

        context 'when initialized with template_name: value' do
          let(:template_name) { 'template.html.erb' }
          let(:options)       { super().merge(template_name:) }

          it 'should return a failing result' do
            expect(command.call(template, **parameters))
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end
      end

      describe 'with valid parameters' do
        let(:parameters) { super().merge(greeting: 'Greetings, starfighter!') }
        let(:expected_value) do
          "<h1>#{parameters[:greeting]}</h1>"
        end

        it 'should return a passing result' do
          expect(command.call(template, **parameters))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with extra parameters' do
        let(:parameters) do
          super().merge(
            extra_parameter: 'extra value',
            greeting:        'Greetings, starfighter!'
          )
        end
        let(:expected_value) do
          "<h1>#{parameters[:greeting]}</h1>"
        end

        it 'should return a passing result' do
          expect(command.call(template, **parameters))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end

    describe 'with a template with compilation errors' do
      let(:template) { '<p><div>Greetings, programs!</div></p>' }
      let(:expected_error) do
        be_a(Cuprum::Cli::Errors::Files::TemplateError).and(
          have_attributes(
            details: /HTML\+ERB Compilation Errors/,
            message: 'unable to render ERB template'
          )
        )
      end

      it 'should return a failing result' do
        expect(command.call(template, **parameters))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with a template with security errors' do
      let(:template) { '<div <%= unsafe %>="value">Greetings, programs!</div>' }
      let(:expected_error) do
        be_a(Cuprum::Cli::Errors::Files::TemplateError).and(
          have_attributes(
            details: /ERB output in attribute names is not allowed/,
            message: 'unable to render ERB template'
          )
        )
      end

      it 'should return a failing result' do
        expect(command.call(template, **parameters))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end
  end

  describe '#template_name' do
    include_examples 'should define reader', :template_name, nil

    context 'when initialized with template_name: value' do
      let(:template_name) { 'template.html.erb' }
      let(:options)       { super().merge(template_name:) }

      it { expect(command.template_name).to be == template_name }
    end
  end
end
