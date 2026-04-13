# frozen_string_literal: true

require 'fileutils'
require 'securerandom'
require 'stringio'

require 'cuprum/cli/dependencies/file_system'
require 'cuprum/cli/rspec/deferred/dependencies/file_system_examples'

RSpec.describe Cuprum::Cli::Dependencies::FileSystem do
  include Cuprum::Cli::RSpec::Deferred::Dependencies::FileSystemExamples

  subject(:file_system) { described_class.new(**options) }

  deferred_context 'with valid file paths' do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:matching_files) do
      %w[
        LICENSE.txt
        spec/examples.txt
        spec/spec_helper.rb
      ].map { |file_name| File.join(file_system.root_path, file_name) }
    end
    let(:files_directory) { 'spec' }
    let(:absolute_directory_path) do
      File.join(Cuprum::Cli.gem_path, 'spec', 'cuprum', 'cli')
    end
    let(:absolute_file_path) do
      File.join(Cuprum::Cli.gem_path, 'spec', 'spec_helper.rb')
    end
    let(:qualified_directory_path) do
      File.join(
        '..',
        File.split(Cuprum::Cli.gem_path).last,
        'spec',
        'cuprum',
        'cli'
      )
    end
    let(:qualified_file_path) do
      File.join(
        '..',
        File.split(Cuprum::Cli.gem_path).last,
        'spec',
        'spec_helper.rb'
      )
    end
    let(:relative_directory_path) do
      File.join('spec', 'cuprum', 'cli')
    end
    let(:relative_file_path) do
      File.join('spec', 'spec_helper.rb')
    end
    let(:writeable_path) { 'tmp' }

    before(:example) do |example|
      next unless example.metadata.fetch(:replace_file_contents, false)

      allow(File).to receive(:read).and_wrap_original do |original, path|
        original.call(path) # Ensure path is valid.

        path = path.sub(%r{\A#{file_system.root_path}/?}, '')

        "Contents of #{path}"
      end
    end
  end

  deferred_context 'when initialized with root_path: value' do
    let(:root_path) do
      if self.class.metadata.fetch(:writeable_root_path, false)
        File.join(Cuprum::Cli.gem_path, 'tmp', 'files')
      else
        File.join(Cuprum::Cli.gem_path, 'spec', 'cuprum')
      end
    end
    let(:options) { super().merge(root_path:) }
    let(:qualified_directory_path) do
      File.join('..', 'cuprum', 'cli')
    end
    let(:qualified_file_path) do
      File.join('..', 'cuprum', 'cli_spec.rb')
    end
    let(:relative_directory_path) do
      'cli'
    end
    let(:relative_file_path) do
      'cli_spec.rb'
    end
  end

  deferred_context 'when created directories are cleaned up' do
    define_method :resolve_to_absolute_path do |path|
      path = File.join(file_system.root_path, path) unless path.start_with?('/')

      File.expand_path(path)
    end

    around(:example) do |example|
      example.call
    ensure
      next if path.nil?

      dir_path = resolve_to_absolute_path(path)

      next if dir_path == file_system.root_path

      expanded_base = resolve_to_absolute_path(base_path)

      dir_path  = dir_path[(1 + File.expand_path(expanded_base).length)..]
      dir_names = dir_path.split(File::SEPARATOR)

      dir_names.size.times do |index|
        dir_name = dir_names[..index].join(File::SEPARATOR)
        dir_name = File.expand_path(File.join(expanded_base, dir_name))

        FileUtils.remove_dir(dir_name, force: true)
      end
    end
  end

  deferred_context 'when created files are cleaned up' do
    define_method :resolve_to_absolute_path do |path|
      path = File.join(file_system.root_path, path) unless path.start_with?('/')

      File.expand_path(path)
    end

    around(:example) do |example|
      example.call
    ensure
      resolved = defined?(file_path) ? file_path : path
      resolved = resolve_to_absolute_path(resolved)

      FileUtils.remove_file(resolved, force: true)
    end
  end

  let(:options)        { {} }
  let(:matching_files) { [] }
  let(:expected_files) { matching_files }

  before(:context) do # rubocop:disable RSpec/BeforeAfterAll
    # :nocov:
    tmp_path = File.join(Cuprum::Cli.gem_path, 'tmp', 'files', 'nested')

    FileUtils.mkdir_p(tmp_path)
    # :nocov:
  end

  before(:example) { allow(Dir).to receive(:[]).and_return(expected_files) }

  describe '::DirectoryIsAFileError' do
    include_examples 'should define constant',
      :DirectoryIsAFileError,
      -> { be_a(Class).and(be < described_class::FileError) }
  end

  describe '::DirectoryNotFoundError' do
    include_examples 'should define constant',
      :DirectoryNotFoundError,
      -> { be_a(Class).and(be < described_class::FileError) }
  end

  describe '::FileError' do
    include_examples 'should define constant',
      :FileError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::FileIsADirectoryError' do
    include_examples 'should define constant',
      :FileIsADirectoryError,
      -> { be_a(Class).and(be < described_class::FileError) }
  end

  describe '::FileNotFoundError' do
    include_examples 'should define constant',
      :FileNotFoundError,
      -> { be_a(Class).and(be < described_class::FileError) }
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:root_path)
    end
  end

  include_deferred 'should implement the file_system dependency'

  describe '#each_file' do
    let(:pattern) { '**/*.rb' }

    it 'should delegate to Dir#[]' do
      file_system.each_file(pattern) { nil }

      expect(Dir)
        .to have_received(:[])
        .with(File.join(file_system.root_path, pattern))
    end

    wrap_deferred 'when initialized with root_path: value' do
      it 'should delegate to Dir#[]' do
        file_system.each_file(pattern) { nil }

        expect(Dir)
          .to have_received(:[])
          .with(File.join(file_system.root_path, pattern))
      end
    end
  end

  describe '#with_tempfile' do
    it 'should clean up the tempfile', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      path = nil

      file_system.with_tempfile do |file|
        path = file.path

        expect(File.exist?(path)).to be true
      end

      expect(File.exist?(path)).to be false
    end
  end
end
