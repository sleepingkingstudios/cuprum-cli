# frozen_string_literal: true

require 'stringio'

require 'cuprum/cli/dependencies/file_system/mock'
require 'cuprum/cli/rspec/deferred/dependencies/file_system_examples'

RSpec.describe Cuprum::Cli::Dependencies::FileSystem::Mock do
  include Cuprum::Cli::RSpec::Deferred::Dependencies::FileSystemExamples

  subject(:mock_fs) { described_class.new(**options) }

  deferred_context 'when initialized with files' do
    let(:files) do
      {
        'root_dir'      => {
          'child_dir'      => {},
          'child_file.txt' => StringIO.new('Child File')
        },
        'root_file.txt' => StringIO.new('Root File')
      }
    end
    let(:options) { super().merge(files:) }
  end

  deferred_context 'with valid file paths' do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:files) do
      {
        'root_dir'      => {
          'child_dir'      => {},
          'child_file.txt' => StringIO.new(
            'Contents of root_dir/child_file.txt'
          )
        },
        'root_file.txt' => StringIO.new('Root File')
      }
    end
    let(:options) { super().merge(files:) }
    let(:matching_files) do
      %w[
        root_dir/child_file.txt
        root_file.txt
      ].map { |file_name| File.join(mock_fs.root_path, file_name) }
    end
    let(:files_directory) { 'root_dir' }
    let(:absolute_directory_path) do
      File.join(mock_fs.root_path, 'root_dir', 'child_dir')
    end
    let(:absolute_file_path) do
      File.join(mock_fs.root_path, 'root_dir', 'child_file.txt')
    end
    let(:qualified_directory_path) do
      File.join(
        '..',
        File.split(mock_fs.root_path).last,
        'root_dir',
        'child_dir'
      )
    end
    let(:qualified_file_path) do
      File.join(
        '..',
        File.split(mock_fs.root_path).last,
        'root_dir',
        'child_file.txt'
      )
    end
    let(:relative_directory_path) do
      File.join('root_dir', 'child_dir')
    end
    let(:relative_file_path) do
      File.join('root_dir', 'child_file.txt')
    end
    let(:writeable_path) do
      File.join('root_dir', 'child_dir')
    end
  end

  deferred_context 'when initialized with root_path: value' do
    let(:root_path) { File.join(Cuprum::Cli.gem_path, 'tmp', 'files') }
    let(:options)   { super().merge(root_path:) }
  end

  deferred_context 'when created files are cleaned up' do
    # Automatically handled by the test scope.
  end

  let(:options) { {} }

  describe '::InvalidPathError' do
    include_examples 'should define constant',
      :InvalidPathError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::MockTempfile' do
    subject(:tempfile) { described_class.new(path) }

    let(:described_class) { super()::MockTempfile }
    let(:path)            { 'path/to/tempfile' }

    describe '.new' do
      it { expect(described_class).to be_constructible.with(1).argument }
    end

    describe '#path' do
      include_examples 'should define reader', :path, -> { path }
    end

    describe '#read' do
      it { expect(tempfile.read).to be == '' }
    end

    describe '#write' do
      let(:value) { 'Contents of tempfile.' }

      it 'should update the file contents' do
        expect { tempfile.write(value) }.to(
          change { tempfile.tap(&:rewind).read }.to(be == value)
        )
      end
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:files, :root_path)
    end
  end

  include_deferred 'should implement the file_system dependency'

  describe '#files' do
    include_examples 'should define reader', :files, {}

    wrap_deferred 'when initialized with files' do
      it { expect(mock_fs.files).to be == files }
    end
  end

  describe '#tempfiles' do
    include_examples 'should define reader', :tempfiles, []
  end

  describe '#with_tempfile' do
    let(:contents) { "Greetings, programs!\n" }

    it 'should clean up the tempfile', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      path = nil

      mock_fs.with_tempfile do |file|
        path = File.split(file.path).last

        expect(mock_fs.files['tempfiles']).to have_key(path)
      end

      expect(mock_fs.files['tempfiles']).not_to have_key(path)
    end

    it 'should copy the file contents to #tempfiles', :aggregate_failures do
      expect { mock_fs.with_tempfile { |file| file.write(contents) } }.to(
        change { mock_fs.tempfiles.size }.by(1)
      )

      expect(mock_fs.tempfiles.last).to be == contents
    end
  end

  describe '#write_file' do
    let(:file_name) { "#{SecureRandom.uuid}.txt" }
    let(:data)      { "Greetings, programs!\n" }

    describe 'with file: a mock Tempfile' do
      let(:tempfile) { described_class::MockTempfile.new('/path/to/file') }

      it 'should write the data to the tempfile' do
        expect { mock_fs.write_file(tempfile, data) }
          .to change(tempfile, :string)
          .to be == data
      end
    end

    describe 'with a path to a tempfile' do
      it 'should write the data to the tempfile', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        mock_fs.with_tempfile do |tempfile|
          expect { mock_fs.write_file(tempfile.path, data) }
            .to change(tempfile, :string)
            .to be == data

          expect(tempfile.pos).to be 0
        end
      end
    end
  end
end
