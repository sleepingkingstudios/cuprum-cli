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
        let(:expected_contents) do
          next super() if defined?(super())

          template = File.read(expected_template_path)
          result   =
            Cuprum::Cli::Files::Engines::RenderErb
            .new
            .call(template, **expected_parameters)

          raise result.error.message if result.failure?

          result.value
        end

        if examples_options.fetch(:require_template, false)
          # :nocov:
          it 'should not generate the file' do
            subject.call

            expect(file_system.file?(expected_file_path)).to be false
          end
          # :nocov:
        else
          it 'should generate the file' do
            subject.call

            expect(file_system.read_file(expected_file_path))
              .to eq(expected_contents)
          end
        end

        if examples_options.fetch(:allow_skip, false)
          context 'when initialized with key: false' do
            let(:constructor_options) do
              super().merge(expected_key => false)
            end

            it 'should not generate the file' do
              subject.call

              expect(file_system.file?(expected_file_path)).to be false
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

            before(:example) do
              file_system.write_file(
                custom_template,
                File.read(expected_template_path)
              )
            end

            it 'should generate the file' do
              subject.call

              expect(file_system.read_file(expected_file_path))
                .to eq(expected_contents)
            end
          end
        end
      end
    end
  end
end
