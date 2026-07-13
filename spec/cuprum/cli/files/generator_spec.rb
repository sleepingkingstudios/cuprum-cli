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

  describe '::AbstractGeneratorError' do
    include_examples 'should define constant',
      :AbstractGeneratorError,
      -> { be_a(Class).and(be < StandardError) }
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

    wrap_deferred 'with a generator subclass' do
      context 'when the generator is an abstract class' do
        before(:example) { described_class.abstract }

        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:match_file)
            .with(1).argument
            .and_a_block
        end

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

    context 'when the generator is an abstract class' do
      it 'should return false' do
        expect(described_class.matches?(file_path, **constructor_options))
          .to be false
      end
    end

    wrap_deferred 'with a generator subclass' do
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
