# frozen_string_literal: true

require 'cuprum/cli/commands/file/new_command'
require 'cuprum/cli/rspec/deferred/arguments_examples'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Commands::File::NewCommand do
  include Cuprum::Cli::RSpec::Deferred::ArgumentsExamples
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:command) do
    described_class.new(file_system:, standard_io:)
  end

  let(:template_paths) do
    described_class
      .default_generators
      .map(&:outputs)
      .map(&:values)
      .flatten
      .map(&:template_path)
      .uniq
  end
  let(:files) do
    template_paths.to_h do |template_path|
      [template_path, File.read(template_path)]
    end
  end
  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new(files:) }
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }

  describe '.default_generators' do
    let(:expected) do
      [
        Cuprum::Cli::Files::Generators::RubyGenerator,
        Cuprum::Cli::Files::Generators::RSpecGenerator
      ]
    end

    include_examples 'should define class reader',
      :default_generators,
      -> { expected }
  end

  include_deferred 'should define argument',
    0,
    :file_path,
    type:     String,
    required: true

  include_deferred 'should define option',
    :directories,
    type:    :boolean,
    default: true

  include_deferred 'should define option',
    :dry_run,
    type:    :boolean,
    default: false

  include_deferred 'should define option',
    :generators,
    type:    :array,
    default: described_class.default_generators

  include_deferred 'should define option',
    :params,
    type:     :object,
    variadic: true

  include_deferred 'should define --quiet option'

  include_deferred 'should define --verbose option'

  describe '#call' do
    let(:generators) do
      [
        Spec::DocsGenerator,
        Spec::RubyGenerator,
        Spec::RSpecGenerator
      ]
    end
    let(:file_path) { 'lib/path/to/file.rb' }
    let(:arguments) { [file_path] }
    let(:options)   { { generators: } }

    before(:example) do
      generators.each do |generator_class|
        mock_generator = instance_double(generator_class, call: nil)

        allow(generator_class).to receive(:new).and_return(mock_generator)
      end
    end

    define_method :call_command do
      command.call(*arguments, **options)
    end

    example_class 'Spec::DocsGenerator', Cuprum::Cli::Files::Generator \
    do |klass|
      klass.match_file '.md'
    end

    example_class 'Spec::RubyGenerator', Cuprum::Cli::Files::Generator \
    do |klass|
      klass.match_file '.rb'
    end

    example_class 'Spec::RSpecGenerator', Cuprum::Cli::Files::Generator \
    do |klass|
      klass.match_file '_spec.rb'
    end

    context 'when the file path does not match a generator' do
      let(:file_path) { 'docs/file.xls' }
      let(:expected_error) do
        details = 'no generator matches the file path and options'
        message = "unable to generate file #{file_path} - #{details}"
        options = command.send(:options)

        Cuprum::Cli::Errors::Files::GeneratorError.new(
          details:,
          file_path:,
          message:,
          options:
        )
      end

      it 'should return a failing result' do
        expect(call_command)
          .to be_a_failing_result
          .with_error(expected_error)
      end

      it 'should not call a generator' do
        call_command

        generators.each do |generator_class|
          expect(generator_class.new).not_to have_received(:call)
        end
      end
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context 'when the file path matches one generator' do
      let(:file_path)        { 'docs/file.md' }
      let(:generator_result) { Cuprum::Result.new(value: [file_path]) }
      let(:expected_value)   { [file_path] }
      let(:generator_options) do
        {
          directories: true,
          dry_run:     false,
          file_system:,
          quiet:       false,
          standard_io:,
          verbose:     false
        }
      end

      before(:example) do
        allow(Spec::DocsGenerator.new)
          .to receive(:call)
          .and_return(generator_result)
      end

      it 'should return a passing result' do
        expect(call_command)
          .to be_a_passing_result
          .with_value(expected_value)
      end

      it 'should initialize the matching generator' do
        call_command

        expect(Spec::DocsGenerator)
          .to have_received(:new)
          .with(file_path, **generator_options)
      end

      it 'should call the matching generator' do
        call_command

        expect(Spec::DocsGenerator.new)
          .to have_received(:call)
      end

      it 'should not call other generators' do
        call_command

        generators.tap { |ary| ary.delete(Spec::DocsGenerator) }.each \
        do |generator_class|
          expect(generator_class.new).not_to have_received(:call)
        end
      end

      context 'when the generator returns a failing result' do
        let(:generator_error) do
          Cuprum::Error.new(message: 'Something went wrong')
        end
        let(:generator_result) do
          Cuprum::Result.new(error: generator_error)
        end

        it 'should return a failing result' do
          expect(call_command)
            .to be_a_failing_result
            .with_error(generator_error)
        end
      end

      describe 'with directories: false' do
        let(:options)           { super().merge(directories: false) }
        let(:generator_options) { super().merge(directories: false) }

        it 'should initialize the matching generator' do
          call_command

          expect(Spec::DocsGenerator)
            .to have_received(:new)
            .with(file_path, **generator_options)
        end
      end

      describe 'with dry_run: true' do
        let(:options)           { super().merge(dry_run: true) }
        let(:generator_options) { super().merge(dry_run: true) }

        it 'should initialize the matching generator' do
          call_command

          expect(Spec::DocsGenerator)
            .to have_received(:new)
            .with(file_path, **generator_options)
        end
      end

      describe 'with quiet: true' do
        let(:options)           { super().merge(quiet: true) }
        let(:generator_options) { super().merge(quiet: true) }

        it 'should initialize the matching generator' do
          call_command

          expect(Spec::DocsGenerator)
            .to have_received(:new)
            .with(file_path, **generator_options)
        end
      end

      describe 'with verbose: true' do
        let(:options)           { super().merge(verbose: true) }
        let(:generator_options) { super().merge(verbose: true) }

        it 'should initialize the matching generator' do
          call_command

          expect(Spec::DocsGenerator)
            .to have_received(:new)
            .with(file_path, **generator_options)
        end
      end

      describe 'with extra parameters' do
        let(:options)           { super().merge(parent_class: Object) }
        let(:generator_options) { super().merge(parent_class: Object) }

        it 'should initialize the matching generator' do
          call_command

          expect(Spec::DocsGenerator)
            .to have_received(:new)
            .with(file_path, **generator_options)
        end
      end
    end

    context 'when the file path matches many generators' do
      let(:file_path)        { 'spec/file_spec.rb' }
      let(:generator_result) { Cuprum::Result.new(value: [file_path]) }
      let(:expected_value)   { [file_path] }
      let(:generator_options) do
        {
          directories: true,
          dry_run:     false,
          file_system:,
          quiet:       false,
          standard_io:,
          verbose:     false
        }
      end

      before(:example) do
        allow(Spec::RSpecGenerator.new)
          .to receive(:call)
          .and_return(generator_result)
      end

      it 'should return a passing result' do
        expect(call_command)
          .to be_a_passing_result
          .with_value(expected_value)
      end

      it 'should initialize the last matching generator' do
        call_command

        expect(Spec::RSpecGenerator)
          .to have_received(:new)
          .with(file_path, **generator_options)
      end

      it 'should call the last matching generator' do
        call_command

        expect(Spec::RSpecGenerator.new)
          .to have_received(:call)
      end

      it 'should not call other generators' do
        call_command

        generators.tap { |ary| ary.delete(Spec::RSpecGenerator) }.each \
        do |generator_class|
          expect(generator_class.new).not_to have_received(:call)
        end
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
end
