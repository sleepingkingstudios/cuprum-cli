# frozen_string_literal: true

require 'cuprum/cli/rspec/deferred'

module Cuprum::Cli::RSpec::Deferred
  # Deferred examples for testing generators options.
  module GeneratorsExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_examples 'should output file' do |output_path, **examples_options|
      description =
        if examples_options.fetch(:as, :default) == :default
          'should output file'
        else
          "should output #{examples_options[:as].inspect} file"
        end

      describe(description) do
        let(:generate_command) do
          instance_double(
            Cuprum::Cli::Files::GenerateFile,
            call: Cuprum::Result.new
          )
        end
        let(:expected_key) do
          next super() if defined?(super())

          examples_options.fetch(:as, :default)
        end
        let(:expected_parameters) do
          next super() if defined?(super())

          subject.file_parameters.merge(subject.options)
        end
        let(:expected_file_path) do
          next super() if defined?(super())

          format(output_path, **expected_parameters)
        end
        let(:expected_template_path) do
          next super() if defined?(super())

          examples_options.fetch(:template)
        end
        let(:expected_keywords) do
          {
            file_path:     expected_file_path,
            parameters:    expected_parameters,
            template_path: expected_template_path
          }
        end

        before(:example) do
          allow(Cuprum::Cli::Files::GenerateFile)
            .to receive(:new)
            .and_return(generate_command)
        end

        if examples_options.fetch(:require_template, false)
          # :nocov:
          it 'should not generate the file' do
            subject.call

            expect(generate_command)
              .not_to have_received(:call)
              .with(**expected_keywords)
          end
          # :nocov:
        else
          it 'should generate the file' do
            subject.call

            expect(generate_command)
              .to have_received(:call)
              .with(**expected_keywords)
          end
        end

        if examples_options.fetch(:allow_skip, false)
          context 'when initialized with key: false' do
            let(:constructor_options) do
              super().merge(expected_key => false)
            end

            it 'should not generate the file' do
              subject.call

              expect(generate_command)
                .not_to have_received(:call)
                .with(**expected_keywords)
            end
          end
        end

        if examples_options.fetch(:allow_custom_template, false) ||
           examples_options.fetch(:require_template, false)
          context 'when initialized with a custom template' do
            let(:custom_template) { 'custom_template.erb' }
            let(:constructor_options) do
              super().merge("#{expected_key}_template": custom_template)
            end
            let(:expected_keywords) do
              super().merge(template_path: custom_template)
            end

            it 'should generate the file' do
              subject.call

              expect(generate_command)
                .to have_received(:call)
                .with(**expected_keywords)
            end
          end
        end
      end
    end
  end
end
