# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'cuprum/cli/rspec/deferred'

module Cuprum::Cli::RSpec::Deferred
  # Deferred examples for testing file generator templates.
  module TemplatesExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_examples 'should apply the configured engine' do
      context 'when initialized with engine: ERB' do
        let(:engine)  { Cuprum::Cli::Files::Engines::ERB }
        let(:options) { super().merge(engine:) }

        it 'should return a passing result with the rendered template' do
          expect(template.call)
            .to be_a_passing_result
            .with_value(raw_value)
        end

        describe 'with extra parameters' do
          let(:parameters) { { extra_parameter: 'extra value' } }

          it 'should return a passing result with the rendered template' do
            expect(template.call(**parameters))
              .to be_a_passing_result
              .with_value(raw_value)
          end
        end

        describe 'with a parameterized template' do
          let(:raw_value) { '<h1><%= greeting %></h1>' }

          describe 'with a missing parameter' do
            let(:expected_template_name) do
              next unless defined?(template_name)

              value = template_name

              value = instance_exec(&value) if value.is_a?(Proc)

              value
            end
            let(:expected_error) do
              Cuprum::Cli::Files::Errors::MissingParameter.new(
                message:        'unable to render ERB template',
                parameter_name: :greeting,
                template_name:  expected_template_name
              )
            end

            it 'should return a failing result' do
              expect(template.call)
                .to be_a_failing_result
                .with_error(expected_error)
            end
          end

          describe 'with a parameter of invalid type' do
            let(:raw_value)  { "<h1><%= greetings.join(', ') %></h1>" }
            let(:parameters) { { greetings: 'Greetings, starfighter!' } }
            let(:expected_template_name) do
              next unless defined?(template_name)

              value = template_name

              value = instance_exec(&value) if value.is_a?(Proc)

              value
            end
            let(:expected_error) do
              message =
                begin
                  'Greetings, starfighter!'.join
                rescue NameError => exception
                  exception.message
                end

              Cuprum::Cli::Files::Errors::TemplateError.new(
                message:       "unable to render ERB template - #{message}",
                template_name: expected_template_name
              )
            end

            it 'should return a failing result' do
              expect(template.call(**parameters))
                .to be_a_failing_result
                .with_error(expected_error)
            end
          end

          describe 'with valid parameters' do
            let(:parameters) { { greeting: 'Greetings, starfighter!' } }
            let(:expected_value) do
              "<h1>#{parameters[:greeting]}</h1>"
            end

            it 'should return a passing result' do
              expect(template.call(**parameters))
                .to be_a_passing_result
                .with_value(expected_value)
            end
          end

          describe 'with extra parameters' do
            let(:parameters) do
              {
                extra_parameter: 'extra value',
                greeting:        'Greetings, starfighter!'
              }
            end
            let(:expected_value) do
              "<h1>#{parameters[:greeting]}</h1>"
            end

            it 'should return a passing result' do
              expect(template.call(**parameters))
                .to be_a_passing_result
                .with_value(expected_value)
            end
          end
        end
      end

      context 'when initialized with engine: an unknown engine' do
        let(:engine)  { 'spec.undefined.engine' }
        let(:options) { super().merge(engine:) }
        let(:expected_error) do
          details = "unknown template engine #{engine.inspect}"

          Cuprum::Cli::Files::Errors::TemplateError.new(
            details:,
            message: "unable to render template - #{details}"
          )
        end

        it 'should return a failing result with a template error' do
          expect(template.call)
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end
    end

    deferred_examples 'should implement the Template interface' do
      describe '#call' do
        let(:parameters) do
          defined?(super()) ? super() : { parameter: 'value' }
        end

        it 'should define the method' do
          expect(subject)
            .to be_callable
            .with(0).arguments
            .and_any_keywords
        end
      end

      describe '#engine' do
        include_examples 'should define reader', :engine, nil

        context 'when initialized with engine: value' do
          let(:engine)  { Cuprum::Cli::Files::Engines::ERB }
          let(:options) { super().merge(engine:) }

          it { expect(subject.engine).to be engine }
        end
      end

      describe '#raw_value' do
        include_examples 'should define private reader', :raw_value
      end
    end
  end
end
