# frozen_string_literal: true

require 'cuprum/cli/files/generator'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Files::Generator do
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:generator) { described_class.new(file_path, **constructor_options) }

  let(:file_path)           { 'lib/path/to/file.md' }
  let(:constructor_options) { {} }

  deferred_context 'with a generator class' do
    let(:described_class) { Spec::CustomGenerator }

    example_class 'Spec::CustomGenerator', Cuprum::Cli::Files::Generator # rubocop:disable RSpec/DescribedClass
  end

  deferred_context 'with a generator subclass' do
    let(:parent_class)    { Spec::CustomGenerator }
    let(:described_class) { Spec::InheritedGenerator }

    example_class 'Spec::CustomGenerator', Cuprum::Cli::Files::Generator # rubocop:disable RSpec/DescribedClass

    example_class 'Spec::InheritedGenerator', 'Spec::CustomGenerator'
  end

  describe '::AbstractGeneratorError' do
    include_examples 'should define constant',
      :AbstractGeneratorError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::OutputAlreadyExistsError' do
    include_examples 'should define constant',
      :OutputAlreadyExistsError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::Output' do
    let(:expected_members) { %i[key path template_path] }

    include_examples 'should define constant',
      :Output,
      lambda {
        be_a(Class)
          .and(be < Data)
          .and(have_attributes(members: expected_members))
      }
  end

  include_deferred 'should define --quiet option'

  include_deferred 'should define --verbose option'

  include_deferred 'should define option',
    :directories,
    type:    :boolean,
    default: true

  include_deferred 'should define option', :dry_run, type: :boolean

  describe '.abstract' do
    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:abstract)
        .with(0).arguments
    end

    wrap_deferred 'with a generator class' do
      it 'should mark the generator as abstract' do
        expect { described_class.abstract }
          .to change(described_class, :abstract?)
          .to be true
      end
    end
  end

  describe '.abstract?' do
    it 'should define the class predicate' do
      expect(described_class)
        .to define_predicate(:abstract?)
    end

    it { expect(described_class.abstract?).to be true }

    wrap_deferred 'with a generator class' do
      it { expect(described_class.abstract?).to be false }
    end
  end

  describe '.match_file' do
    let(:error_message) do
      "unable to define matcher - #{described_class} is an abstract class"
    end

    define_method :defined_matchers do
      described_class.send :matchers
    end

    define_method :handle_exception do |&block|
      block.call
    rescue StandardError
      nil
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:match_file)
        .with(1).argument
        .and_a_block
    end

    it 'should raise an exception' do
      expect { described_class.match_file('.md') }
        .to raise_error described_class::AbstractGeneratorError, error_message
    end

    it 'should not add a matcher' do
      expect { handle_exception { described_class.match_file('.md') } }
        .not_to(change { defined_matchers })
    end

    wrap_deferred 'with a generator class' do
      context 'when the generator is an abstract class' do
        before(:example) { described_class.abstract }

        it 'should raise an exception' do
          expect { described_class.match_file('.md') }.to raise_error(
            described_class::AbstractGeneratorError,
            error_message
          )
        end

        it 'should not add a matcher' do
          expect { handle_exception { described_class.match_file('.md') } }
            .not_to(change { defined_matchers })
        end
      end

      describe 'with a block' do
        let(:block) { ->(*, **) { true } }

        it 'should add the matcher' do
          expect { described_class.match_file(&block) }.to(
            change { defined_matchers }.to(include(block))
          )
        end
      end

      describe 'with a Regexp' do
        let(:pattern) { /\.md\z/ }

        it 'should add the matcher' do
          expect { described_class.match_file(pattern) }.to(
            change { defined_matchers }.to(include(pattern))
          )
        end
      end

      describe 'with a String' do
        let(:pattern) { '.md' }

        it 'should add the matcher' do
          expect { described_class.match_file(pattern) }.to(
            change { defined_matchers }.to(include(pattern))
          )
        end
      end
    end
  end

  describe '.matches?' do
    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:matches?)
        .with(1).argument
        .and_any_keywords
    end

    it { expect(described_class).to have_aliased_method(:matches?).as(:match?) }

    it 'should return false' do
      expect(described_class.matches?(file_path, **constructor_options))
        .to be false
    end

    wrap_deferred 'with a generator class' do
      context 'when there are no defined matchers' do
        it 'should return false' do
          expect(described_class.matches?(file_path, **constructor_options))
            .to be false
        end
      end

      context 'when the generator has a non-matching block matcher' do
        before(:example) do
          described_class.match_file do |input_path, **|
            input_path.start_with?('spec')
          end
        end

        it 'should return false' do
          expect(described_class.matches?(file_path, **constructor_options))
            .to be false
        end
      end

      context 'when the generator has a matching block matcher' do
        before(:example) do
          described_class.match_file do |input_path, **|
            input_path.start_with?('lib')
          end
        end

        it 'should return true' do
          expect(described_class.matches?(file_path, **constructor_options))
            .to be true
        end
      end

      context 'when the generator has a non-matching Regexp matcher' do
        let(:pattern) { /\.yml\z/ }

        before(:example) do
          described_class.match_file(pattern)
        end

        it 'should return false' do
          expect(described_class.matches?(file_path, **constructor_options))
            .to be false
        end
      end

      context 'when the generator has a matching Regexp matcher' do
        let(:pattern) { /\.md\z/ }

        before(:example) do
          described_class.match_file(pattern)
        end

        it 'should return true' do
          expect(described_class.matches?(file_path, **constructor_options))
            .to be true
        end
      end

      context 'when the generator has a non-matching String matcher' do
        let(:pattern) { '.yml' }

        before(:example) do
          described_class.match_file(pattern)
        end

        it 'should return false' do
          expect(described_class.matches?(file_path, **constructor_options))
            .to be false
        end
      end

      context 'when the generator has a matching String matcher' do
        let(:pattern) { '.md' }

        before(:example) do
          described_class.match_file(pattern)
        end

        it 'should return true' do
          expect(described_class.matches?(file_path, **constructor_options))
            .to be true
        end
      end
    end

    wrap_deferred 'with a generator subclass' do
      context 'when there are no defined matchers' do
        it 'should return false' do
          expect(described_class.matches?(file_path, **constructor_options))
            .to be false
        end
      end

      context 'when the parent class has a matching pattern' do
        let(:pattern) { '.md' }

        before(:example) do
          parent_class.match_file(pattern)
        end

        it 'should return true' do
          expect(described_class.matches?(file_path, **constructor_options))
            .to be true
        end
      end
    end
  end

  describe '.output' do
    let(:output_path) { 'tmp/out.md' }
    let(:key)         { :default }
    let(:options)     { {} }
    let(:error_message) do
      "unable to define output #{key.inspect} - #{described_class} is an " \
        'abstract class'
    end

    define_method :handle_exception do |&block|
      block.call
    rescue StandardError
      nil
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:output)
        .with(1).argument
        .and_keywords(:key, :template_path)
    end

    it 'should raise an exception' do
      expect { described_class.output(file_path, **options) }
        .to raise_error described_class::AbstractGeneratorError, error_message
    end

    it 'should not add a matcher' do
      expect do
        handle_exception { described_class.output(file_path, **options) }
      end
        .not_to change(described_class, :outputs)
    end

    describe 'with key: value' do
      let(:key)     { :markdown }
      let(:options) { super().merge(key:) }

      it 'should raise an exception' do
        expect { described_class.output(file_path, **options) }
          .to raise_error described_class::AbstractGeneratorError, error_message
      end

      it 'should not add a matcher' do
        expect do
          handle_exception { described_class.output(file_path, **options) }
        end
          .not_to change(described_class, :outputs)
      end
    end

    wrap_deferred 'with a generator class' do
      let(:expected_properties) do
        {
          key:,
          path:          output_path,
          template_path: nil
        }
      end

      it 'should set the output', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        expect { described_class.output(output_path, **options) }
          .to change(described_class, :outputs)
          .to have_key(key)

        expect(described_class.outputs[key])
          .to be_a(described_class::Output)
          .and(have_attributes(**expected_properties))
      end

      describe 'with key: value' do
        let(:key)     { :markdown }
        let(:options) { super().merge(key:) }

        it 'should set the output', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
          expect { described_class.output(output_path, **options) }
            .to change(described_class, :outputs)
            .to have_key(key)

          expect(described_class.outputs[key])
            .to be_a(described_class::Output)
            .and(have_attributes(**expected_properties))
        end

        context 'when the generator has an output with the same key' do
          let(:error_message) do
            "unable to define output #{key.inspect} - #{described_class} " \
              "already defines output #{key.inspect}"
          end

          before(:example) { described_class.output 'duplicate.txt', key: }

          it 'should raise an exception' do
            expect { described_class.output(file_path, **options) }
              .to raise_error(
                described_class::OutputAlreadyExistsError,
                error_message
              )
          end

          it 'should not add a matcher' do
            expect do
              handle_exception { described_class.output(file_path, **options) }
            end
              .not_to change(described_class, :outputs)
          end
        end
      end

      describe 'with template_path: value' do
        let(:template_path) { 'path/to/template.md' }
        let(:options)       { super().merge(template_path:) }
        let(:expected_properties) do
          super().merge(template_path:)
        end

        it 'should set the output', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
          expect { described_class.output(output_path, **options) }
            .to change(described_class, :outputs)
            .to have_key(key)

          expect(described_class.outputs[key])
            .to be_a(described_class::Output)
            .and(have_attributes(**expected_properties))
        end
      end

      context 'when the generator is an abstract class' do
        before(:example) { described_class.abstract }

        it 'should raise an exception' do
          expect { described_class.output(file_path, **options) }
            .to raise_error(
              described_class::AbstractGeneratorError,
              error_message
            )
        end

        it 'should not add a matcher' do
          expect do
            handle_exception { described_class.output(file_path, **options) }
          end
            .not_to change(described_class, :outputs)
        end
      end

      context 'when the generator has an output with the same key' do
        let(:error_message) do
          "unable to define output #{key.inspect} - #{described_class} " \
            "already defines output #{key.inspect}"
        end

        before(:example) { described_class.output 'duplicate.txt', key: }

        it 'should raise an exception' do
          expect { described_class.output(file_path, **options) }
            .to raise_error(
              described_class::OutputAlreadyExistsError,
              error_message
            )
        end

        it 'should not add a matcher' do
          expect do
            handle_exception { described_class.output(file_path, **options) }
          end
            .not_to change(described_class, :outputs)
        end
      end
    end

    wrap_deferred 'with a generator subclass' do
      context 'when the parent class has an output with the same key' do
        let(:expected_properties) do
          {
            key:,
            path:          output_path,
            template_path: nil
          }
        end

        before(:example) { parent_class.output 'duplicate.txt', key: }

        it 'should update the output', :aggregate_failures do
          expect { described_class.output(output_path, **options) }
            .to change(described_class, :outputs)

          expect(described_class.outputs[key])
            .to be_a(described_class::Output)
            .and(have_attributes(**expected_properties))
        end
      end
    end
  end

  describe '.outputs' do
    include_examples 'should define class reader', :outputs, {}

    wrap_deferred 'with a generator class' do
      it { expect(described_class.outputs).to be == {} }

      context 'when the generator has one output' do
        let(:expected_outputs) do
          {
            default: described_class::Output.new(
              key:           :default,
              path:          'docs/out.md',
              template_path: nil
            )
          }
        end

        before(:example) do
          described_class.output 'docs/out.md'
        end

        it { expect(described_class.outputs).to be == expected_outputs }
      end

      context 'when the generator has multiple outputs' do
        let(:expected_outputs) do
          {
            default:    described_class::Output.new(
              key:           :default,
              path:          'docs/out.md',
              template_path: nil
            ),
            plain_text: described_class::Output.new(
              key:           :plain_text,
              path:          'docs/out.txt',
              template_path: 'templates/plain_text.txt'
            )
          }
        end

        before(:example) do
          described_class.output 'docs/out.md'
          described_class.output 'docs/out.txt',
            key:           :plain_text,
            template_path: 'templates/plain_text.txt'
        end

        it { expect(described_class.outputs).to be == expected_outputs }
      end
    end

    wrap_deferred 'with a generator subclass' do
      it { expect(described_class.outputs).to be == {} }

      context 'when the parent class has multiple outputs' do
        let(:expected_outputs) do
          {
            default:    described_class::Output.new(
              key:           :default,
              path:          'docs/out.md',
              template_path: nil
            ),
            plain_text: described_class::Output.new(
              key:           :plain_text,
              path:          'docs/out.txt',
              template_path: 'templates/plain_text.txt'
            )
          }
        end

        before(:example) do
          parent_class.output 'docs/out.md'
          parent_class.output 'docs/out.txt',
            key:           :plain_text,
            template_path: 'templates/plain_text.txt'
        end

        it { expect(described_class.outputs).to be == expected_outputs }
      end

      context 'when the parent class and generator have multiple outputs' do
        let(:expected_outputs) do
          {
            default:    described_class::Output.new(
              key:           :default,
              path:          'docs/out/default.txt',
              template_path: 'templates/default.txt'
            ),
            plain_text: described_class::Output.new(
              key:           :plain_text,
              path:          'docs/out.txt',
              template_path: 'templates/plain_text.txt'
            ),
            signature:  described_class::Output.new(
              key:           :signature,
              path:          'docs/signature.txt',
              template_path: nil
            )
          }
        end

        before(:example) do
          parent_class.output 'docs/out.md'
          parent_class.output 'docs/out.txt',
            key:           :plain_text,
            template_path: 'templates/plain_text.txt'

          described_class.output 'docs/signature.txt', key: :signature
          described_class.output 'docs/out/default.txt',
            key:           :default,
            template_path: 'templates/default.txt'
        end

        it { expect(described_class.outputs).to be == expected_outputs }
      end
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_keywords(:file_system, :standard_io)
        .and_any_keywords
    end

    describe 'with extra options' do
      let(:constructor_options) do
        super().merge(extra_option: 'value')
      end
      let(:error_message) do
        'unrecognized option :extra_option for Cuprum::Cli::Files::Generator ' \
          '- valid options are :directories, :dry_run, :quiet, :verbose'
      end

      it 'should raise an exception' do
        expect { described_class.new(file_path, **constructor_options) }
          .to raise_error(
            Cuprum::Cli::Options::UnknownOptionError,
            error_message
          )
      end
    end

    describe 'with invalid options' do
      let(:constructor_options) do
        super().merge(dry_run: 'value')
      end
      let(:error_message) do
        'invalid value for option :dry_run - expected true or false, ' \
          'received "value"'
      end

      it 'should raise an exception' do
        expect { described_class.new(file_path, **constructor_options) }
          .to raise_error(
            Cuprum::Cli::Options::InvalidOptionError,
            error_message
          )
      end
    end
  end

  describe '#call' do
    let(:file_system) do
      Cuprum::Cli::Dependencies::FileSystem::Mock.new
    end
    let(:standard_io) do
      Cuprum::Cli::Dependencies::StandardIo::Mock.new
    end
    let(:constructor_options) { { file_system:, standard_io: } }
    let(:expected_error) do
      details = 'generator does not define any outputs'

      Cuprum::Cli::Errors::Files::GeneratorError.new(
        details:,
        file_path:,
        message:   "unable to generate output files - #{details}",
        options:   generator.options
      )
    end

    it { expect(generator).to be_callable.with(0).arguments }

    it 'should return a failing result' do
      expect(generator.call)
        .to be_a_failing_result
        .with_error(expected_error)
    end

    wrap_deferred 'with a generator class' do
      deferred_examples 'should not generate any output files' do
        it 'should not generate any output files' do
          expect { generator.call }.not_to change(file_system, :files)
        end

        it 'should not write to any output stream' do
          generator.call

          expect(standard_io.combined_stream.string).to be == ''
        end
      end

      deferred_examples 'should generate the output files' do
        let(:expected_output_text) do
          expected_output_files
            .each_key
            .map { |file_path| "Generating file #{file_path}...\n" }
            .join
        end

        define_method :generated_files do
          file_system
            .flattened_files
            .reject { |file_path| file_path.start_with?('spec/support') }
            .reject { |file_path| file_path.start_with?('tmp') }
        end

        it 'should generate each output file', :aggregate_failures do
          generator.call

          expect(generated_files).to match_array(expected_output_files.keys)

          expected_output_files.each do |output_path, contents|
            expect(file_system.read_file(output_path)).to be == contents
          end
        end

        it 'should report the files to the output stream',
          :aggregate_failures \
        do
          generator.call

          expect(standard_io.output_stream.string).to be == expected_output_text
          expect(standard_io.error_stream.string).to be == ''
        end

        context 'when initialized with dry_run: true' do
          let(:constructor_options) { super().merge(dry_run: true) }

          it 'should not generate any output files' do
            expect { generator.call }.not_to change(file_system, :files)
          end

          it 'should report the files to the output stream',
            :aggregate_failures \
          do
            generator.call

            expect(standard_io.output_stream.string)
              .to be == expected_output_text
            expect(standard_io.error_stream.string).to be == ''
          end
        end

        context 'when initialized with quiet: true' do
          let(:constructor_options) { super().merge(quiet: true) }

          it 'should generate each output file', :aggregate_failures do
            generator.call

            expected_output_files.each do |output_path, contents|
              expect(file_system.read_file(output_path)).to be == contents
            end
          end

          it 'should not write to any output stream' do
            generator.call

            expect(standard_io.combined_stream.string).to be == ''
          end
        end

        context 'when initialized with verbose: true' do
          let(:constructor_options) { super().merge(verbose: true) }
          let(:expected_output_text) do
            expected_output_files
              .each
              .map do |file_path, contents|
                indented =
                  contents
                  .each_line
                  .map { |line| line.strip.empty? ? "\n" : "  #{line}" }
                  .join

                "Generating file #{file_path}...\n\n#{indented}\n"
              end
              .join
          end

          it 'should generate each output file', :aggregate_failures do
            generator.call

            expected_output_files.each do |output_path, contents|
              expect(file_system.read_file(output_path)).to be == contents
            end
          end

          it 'should report the files to the output stream',
            :aggregate_failures \
          do
            generator.call

            expect(standard_io.output_stream.string)
              .to be == expected_output_text
            expect(standard_io.error_stream.string).to be == ''
          end
        end
      end

      let(:templates_directory) do
        File.join(Cuprum::Cli.gem_path, 'spec', 'support', 'templates')
      end
      let(:generate_result) { Cuprum::Result.new }
      let(:expected_value)  { expected_output_files.keys }

      define_method :render_template do |template_path|
        template = file_system.read_file(template_path)

        if template_path.end_with?('.erb')
          command  = Cuprum::Cli::Files::RenderErb.new
          params   = generator.file_parameters.merge(generator.options)
          template = command.call(template, **params).value
        end

        template
      end

      before(:example) do
        file_system.create_directory(templates_directory, recursive: true)

        Dir["#{templates_directory}/*"].each do |file_path|
          relative_path =
            File.join(templates_directory, File.basename(file_path))

          file_system.write_file(relative_path, File.read(file_path))
        end
      end

      it 'should return a failing result' do
        expect(generator.call)
          .to be_a_failing_result
          .with_error(expected_error)
      end

      include_deferred 'should not generate any output files'

      # rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
      context 'when the generator has one output' do
        let(:output_path)    { 'docs/%<relative_path>s/%<short_name>s.md' }
        let(:output_options) { {} }
        let(:expected_output_files) do
          template_path = File.join(templates_directory, 'docs.md.erb')

          {
            'docs/path/to/file.md' => render_template(template_path)
          }
        end

        before(:example) do
          described_class.output(output_path, **output_options)
        end

        context 'when the output path has missing wildcards' do
          let(:template_path) do
            File.join(templates_directory, 'docs.md.erb')
          end
          let(:output_options) { super().merge(template_path:) }
          let(:output_path)    { 'docs/%<secret_path>s/%<short_name>s.md' }
          let(:expected_error) do
            details =
              "missing parameter :secret_path for output path #{output_path}"

            Cuprum::Cli::Errors::Files::GeneratorError.new(
              details:,
              file_path:,
              message:   "unable to generate output file :default - #{details}",
              options:   generator.options
            )
          end

          it 'should return a failing result' do
            expect(generator.call)
              .to be_a_failing_result
              .with_error(expected_error)
          end

          include_deferred 'should not generate any output files'

          context 'when the generator defines a matching option' do
            before(:example) { described_class.option :secret_path }

            it 'should return a failing result' do
              expect(generator.call)
                .to be_a_failing_result
                .with_error(expected_error)
            end

            include_deferred 'should not generate any output files'

            context 'when initialized with a matching value' do
              let(:constructor_options) do
                super().merge(secret_path: 'path/to/secret')
              end
              let(:expected_output_files) do
                template_path = File.join(templates_directory, 'docs.md.erb')
                rendered      = render_template(template_path)

                {
                  'docs/path/to/secret/file.md' => rendered
                }
              end

              it 'should return a passing result' do
                expect(generator.call)
                  .to be_a_passing_result
                  .with_value(expected_value)
              end

              include_deferred 'should generate the output files'
            end
          end
        end

        context 'when the template path is not defined' do
          let(:expected_error) do
            details = 'output does not define a template path'
            message = "unable to generate output file :default - #{details}"

            Cuprum::Cli::Errors::Files::GeneratorError.new(
              details:,
              file_path:,
              message:,
              options:   generator.options
            )
          end

          it 'should return a failing result' do
            expect(generator.call)
              .to be_a_failing_result
              .with_error(expected_error)
          end

          include_deferred 'should not generate any output files'

          context 'when the generator defines a :template option' do
            before(:example) { described_class.option :template }

            it 'should return a failing result' do
              expect(generator.call)
                .to be_a_failing_result
                .with_error(expected_error)
            end

            include_deferred 'should not generate any output files'

            context 'when initialized with template: value' do
              let(:custom_template_path) { 'tmp/custom_template.md.erb' }
              let(:constructor_options) do
                super().merge(template: custom_template_path)
              end
              let(:expected_output_files) do
                rendered = render_template(custom_template_path)

                {
                  'docs/path/to/file.md' => rendered
                }
              end

              before(:example) do
                file_system.create_directory('tmp')
                file_system.write(
                  custom_template_path,
                  file_system.read(
                    File.join(templates_directory, 'docs.md.erb')
                  )
                )
              end

              include_deferred 'should generate the output files'
            end
          end

          context 'when the generator defines a :default_template option' do
            before(:example) { described_class.option :default_template }

            it 'should return a failing result' do
              expect(generator.call)
                .to be_a_failing_result
                .with_error(expected_error)
            end

            include_deferred 'should not generate any output files'

            context 'when initialized with default_template: value' do
              let(:custom_template_path) { 'tmp/custom_template.md.erb' }
              let(:constructor_options) do
                super().merge(default_template: custom_template_path)
              end
              let(:expected_output_files) do
                rendered = render_template(custom_template_path)

                {
                  'docs/path/to/file.md' => rendered
                }
              end

              before(:example) do
                file_system.create_directory('tmp')
                file_system.write(
                  custom_template_path,
                  file_system.read(
                    File.join(templates_directory, 'docs.md.erb')
                  )
                )
              end

              include_deferred 'should generate the output files'
            end
          end
        end

        context 'when the template path is defined' do
          let(:template_path)  { File.join(templates_directory, 'docs.md.erb') }
          let(:output_options) { super().merge(template_path:) }

          it 'should return a passing result' do
            expect(generator.call)
              .to be_a_passing_result
              .with_value(expected_value)
          end

          include_deferred 'should generate the output files'

          context 'when the generator defines a :template option' do
            before(:example) { described_class.option :template }

            include_deferred 'should generate the output files'

            context 'when initialized with template: value' do
              let(:custom_template_path) { 'tmp/custom_template.md.erb' }
              let(:constructor_options) do
                super().merge(template: custom_template_path)
              end

              before(:example) do
                file_system.create_directory('tmp')
                file_system.write(
                  custom_template_path,
                  file_system.read(
                    File.join(templates_directory, 'docs.md.erb')
                  )
                )
              end

              include_deferred 'should generate the output files'
            end
          end

          context 'when the generator defines a :default_template option' do
            before(:example) { described_class.option :default_template }

            include_deferred 'should generate the output files'

            context 'when initialized with default_template: value' do
              let(:custom_template_path) { 'tmp/custom_template.md.erb' }
              let(:constructor_options) do
                super().merge(default_template: custom_template_path)
              end

              before(:example) do
                file_system.create_directory('tmp')
                file_system.write(
                  custom_template_path,
                  file_system.read(
                    File.join(templates_directory, 'docs.md.erb')
                  )
                )
              end

              include_deferred 'should generate the output files'
            end
          end
        end

        context 'when the output has a key' do
          let(:output_options) { super().merge(key: :docs) }

          context 'when the template path is not defined' do
            let(:expected_error) do
              details = 'output does not define a template path'
              message = "unable to generate output file :docs - #{details}"

              Cuprum::Cli::Errors::Files::GeneratorError.new(
                details:,
                file_path:,
                message:,
                options:   generator.options
              )
            end

            it 'should return a failing result' do
              expect(generator.call)
                .to be_a_failing_result
                .with_error(expected_error)
            end

            include_deferred 'should not generate any output files'

            context 'when the generator defines a :docs_template option' do
              before(:example) { described_class.option :docs_template }

              it 'should return a failing result' do
                expect(generator.call)
                  .to be_a_failing_result
                  .with_error(expected_error)
              end

              include_deferred 'should not generate any output files'

              context 'when initialized with docs_template: value' do
                let(:custom_template_path) { 'tmp/custom_template.md.erb' }
                let(:constructor_options) do
                  super().merge(docs_template: custom_template_path)
                end

                before(:example) do
                  file_system.create_directory('tmp')
                  file_system.write(
                    custom_template_path,
                    file_system.read(
                      File.join(templates_directory, 'docs.md.erb')
                    )
                  )
                end

                include_deferred 'should generate the output files'
              end
            end
          end

          context 'when the template path is defined' do
            let(:template_path) do
              File.join(templates_directory, 'docs.md.erb')
            end
            let(:output_options) { super().merge(template_path:) }

            it 'should return a passing result' do
              expect(generator.call)
                .to be_a_passing_result
                .with_value(expected_value)
            end

            include_deferred 'should generate the output files'

            context 'when the generator defines a :docs_template option' do
              before(:example) { described_class.option :docs_template }

              include_deferred 'should generate the output files'

              context 'when initialized with docs_template: value' do
                let(:custom_template_path) { 'tmp/custom_template.md.erb' }
                let(:constructor_options) do
                  super().merge(docs_template: custom_template_path)
                end

                before(:example) do
                  file_system.create_directory('tmp')
                  file_system.write(
                    custom_template_path,
                    file_system.read(
                      File.join(templates_directory, 'docs.md.erb')
                    )
                  )
                end

                include_deferred 'should generate the output files'
              end
            end
          end

          context 'when the generator defines a matching predicate option' do
            let(:template_path) do
              File.join(templates_directory, 'docs.md.erb')
            end
            let(:output_options) { super().merge(template_path:) }

            before(:example) do
              described_class.option :docs, type: :boolean, default: true
            end

            include_deferred 'should generate the output files'

            context 'when initialized with matching option: false' do
              let(:constructor_options) { super().merge(docs: false) }
              let(:expected_error) do
                details = 'all outputs have been disabled'

                Cuprum::Cli::Errors::Files::GeneratorError.new(
                  details:,
                  file_path:,
                  message:   "unable to generate output files - #{details}",
                  options:   generator.options
                )
              end

              it 'should return a failing result' do
                expect(generator.call)
                  .to be_a_failing_result
                  .with_error(expected_error)
              end

              include_deferred 'should not generate any output files'
            end

            context 'when initialized with matching option: true' do
              let(:constructor_options) { super().merge(docs: true) }

              include_deferred 'should generate the output files'
            end
          end
        end
      end

      context 'when the generator has many outputs' do
        let(:file_path) { 'lib/path/to/file.rb' }
        let(:expected_output_files) do
          docs_path = File.join(templates_directory, 'docs.md.erb')
          ruby_path = File.join(templates_directory, 'ruby.rb.erb')
          spec_path = File.join(templates_directory, 'rspec.rb.erb')

          {
            'lib/path/to/file.rb'       => render_template(ruby_path),
            'docs/path/to/file.md'      => render_template(docs_path),
            'spec/path/to/file_spec.rb' => render_template(spec_path)
          }
        end

        before(:example) do
          described_class.output '%<file_path>s',
            template_path: File.join(templates_directory, 'ruby.rb.erb')

          described_class.output 'docs/%<relative_path>s/%<short_name>s.md',
            key:           :docs,
            template_path: File.join(templates_directory, 'docs.md.erb')

          described_class.output \
            'spec/%<relative_path>s/%<short_name>s_spec.rb',
            key:           :rspec,
            template_path: File.join(templates_directory, 'rspec.rb.erb')
        end

        it 'should return a passing result' do
          expect(generator.call)
            .to be_a_passing_result
            .with_value(expected_value)
        end

        include_deferred 'should generate the output files'

        context 'when the generator defines filtering options' do
          before(:example) do
            described_class.option :docs,  type: :boolean, default: true
            described_class.option :rspec, type: :boolean, default: true
          end

          include_deferred 'should generate the output files'

          context 'when initialized with filtering options' do
            let(:constructor_options) { super().merge(rspec: false) }
            let(:expected_output_files) do
              docs_path = File.join(templates_directory, 'docs.md.erb')
              ruby_path = File.join(templates_directory, 'ruby.rb.erb')

              {
                'lib/path/to/file.rb'  => render_template(ruby_path),
                'docs/path/to/file.md' => render_template(docs_path)
              }
            end

            include_deferred 'should generate the output files'
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
    end
  end

  describe '#file_parameters' do
    let(:expected) do
      {
        base_name:     'file.md',
        dir_name:      'lib/path/to',
        ext_name:      '.md',
        file_path:,
        relative_path: 'path/to',
        root_path:     'lib',
        short_name:    'file'
      }
    end

    include_examples 'should define reader', :file_parameters, -> { expected }

    describe 'with a file path in the working directory' do
      let(:file_path) { 'file.md' }
      let(:expected) do
        super().merge(
          dir_name:      '.',
          relative_path: '',
          root_path:     ''
        )
      end

      it { expect(generator.file_parameters).to be == expected }
    end
  end

  describe '#file_path' do
    include_examples 'should define reader', :file_path, -> { file_path }
  end

  describe '#file_system' do
    let(:expected) { Cuprum::Cli::Dependencies.provider.get(:file_system) }

    include_examples 'should define reader', :file_system, -> { expected }

    context 'when initialized with file_system: value' do
      let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new }
      let(:constructor_options) do
        super().merge(file_system:)
      end

      it { expect(generator.file_system).to be file_system }
    end
  end

  describe '#options' do
    let(:expected) do
      {
        directories: true,
        dry_run:     false,
        quiet:       false,
        verbose:     false
      }
    end

    include_examples 'should define reader', :options, -> { expected }
  end

  describe '#resolve_output_path' do
    let(:output) do
      described_class::Output.new(
        key:           :default,
        path:          output_path,
        template_path: nil
      )
    end
    let(:resolved_path) do
      generator.send(:resolve_output_path, output)
    end

    it 'should define the private method' do
      expect(generator)
        .to respond_to(:resolve_output_path, true)
        .with(1).argument
    end

    describe 'with a string without parameters' do
      let(:output_path) { 'lib/path/to/file.md' }

      it { expect(resolved_path).to be == output_path }

      context 'when the string has consecutive file separators' do
        let(:output_path) { 'lib/path//file.md' }
        let(:expected)    { 'lib/path/file.md' }

        it { expect(resolved_path).to be == expected }
      end
    end

    describe 'with a string with a :base_name parameter' do
      let(:output_path) { 'lib/path/to/%<base_name>s' }
      let(:expected)    { 'lib/path/to/file.md' }

      it { expect(resolved_path).to be == expected }
    end

    describe 'with a string with a :dir_name parameter' do
      let(:output_path) { '%<dir_name>s/copy.md' }
      let(:expected)    { 'lib/path/to/copy.md' }

      it { expect(resolved_path).to be == expected }
    end

    describe 'with a string with an :ext_name parameter' do
      let(:output_path) { 'docs/copy%<ext_name>s' }
      let(:expected)    { 'docs/copy.md' }

      it { expect(resolved_path).to be == expected }
    end

    describe 'with a string with a :file_path parameter' do
      let(:output_path) { 'archive/%<file_path>s' }
      let(:expected)    { 'archive/lib/path/to/file.md' }

      it { expect(resolved_path).to be == expected }
    end

    describe 'with a string with a :relative_path parameter' do
      let(:output_path) { 'docs/%<relative_path>s/copy.md' }
      let(:expected)    { 'docs/path/to/copy.md' }

      it { expect(resolved_path).to be == expected }
    end

    describe 'with a string with a :root_path parameter' do
      let(:output_path) { '%<root_path>s/other/path/copy.md' }
      let(:expected)    { 'lib/other/path/copy.md' }

      it { expect(resolved_path).to be == expected }
    end

    describe 'with a string with a :short_name parameter' do
      let(:output_path) { 'docs/archived/%<short_name>s.md' }
      let(:expected)    { 'docs/archived/file.md' }

      it { expect(resolved_path).to be == expected }
    end
  end

  describe '#standard_io' do
    let(:expected) { Cuprum::Cli::Dependencies.provider.get(:standard_io) }

    include_examples 'should define reader', :standard_io, -> { expected }

    context 'when initialized with standard_io: value' do
      let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }
      let(:constructor_options) do
        super().merge(standard_io:)
      end

      it { expect(generator.standard_io).to be standard_io }
    end
  end
end
