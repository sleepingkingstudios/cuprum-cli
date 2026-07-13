# frozen_string_literal: true

require 'cuprum/cli/files/generator'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Files::Generator do
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:generator) { described_class.new(file_path, **constructor_options) }

  let(:file_path)           { 'lib/path/to/file.md' }
  let(:constructor_options) { {} }

  deferred_context 'with a generator subclass' do
    let(:described_class) { Spec::CustomGenerator }

    example_class 'Spec::CustomGenerator', Cuprum::Cli::Files::Generator # rubocop:disable RSpec/DescribedClass
  end

  include_deferred 'should define --quiet option'

  include_deferred 'should define --verbose option'

  include_deferred 'should define option', :dry_run, type: :boolean

  describe '.abstract' do
    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:abstract)
        .with(0).arguments
    end

    wrap_deferred 'with a generator subclass' do
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

    wrap_deferred 'with a generator subclass' do
      it { expect(described_class.abstract?).to be false }
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_any_keywords
    end

    describe 'with extra options' do
      let(:constructor_options) do
        super().merge(extra_option: 'value')
      end
      let(:error_message) do
        'unrecognized option :extra_option for Cuprum::Cli::Files::Generator ' \
          '- valid options are :dry_run, :quiet, :verbose'
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

  describe '#options' do
    let(:expected) do
      {
        dry_run: false,
        quiet:   false,
        verbose: false
      }
    end

    include_examples 'should define reader', :options, -> { expected }
  end

  describe '#resolve_output_path' do
    let(:resolved_path) do
      generator.send(:resolve_output_path, output_path)
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
end
