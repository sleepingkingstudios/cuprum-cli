# frozen_string_literal: true

require 'stringio'

require 'cuprum/cli/dependencies/file_system/mock'

RSpec.describe Cuprum::Cli::Dependencies::FileSystem::Mock do
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

  describe '#directory?' do
    it 'should define the method' do
      expect(mock_fs).to respond_to(:directory?).with(1).argument
    end

    it 'should define the aliased method' do
      expect(mock_fs)
        .to have_aliased_method(:directory?)
        .as(:directory_exists?)
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'path')
      end

      it 'should raise an exception' do
        expect { mock_fs.directory?(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('name', as: 'path')
      end

      it 'should raise an exception' do
        expect { mock_fs.directory?(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'path')
      end

      it 'should raise an exception' do
        expect { mock_fs.directory?('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an invalid absolute path' do
      let(:path) { '/invalid-absolute-path' }

      it { expect(mock_fs.directory?(path)).to be false }
    end

    describe 'with an invalid qualified path' do
      let(:path) { '../invalid-qualified-path' }

      it { expect(mock_fs.directory?(path)).to be false }
    end

    describe 'with an invalid relative path' do
      let(:path) { 'invalid-relative-path' }

      it { expect(mock_fs.directory?(path)).to be false }
    end

    wrap_deferred 'when initialized with files' do
      describe 'with an absolute path to a directory' do
        let(:path) do
          File.join(mock_fs.root_path, 'root_dir', 'child_dir')
        end

        it { expect(mock_fs.directory?(path)).to be true }
      end

      describe 'with an absolute path to a file' do
        let(:path) do
          File.join(mock_fs.root_path, 'root_dir', 'child_file.txt')
        end

        it { expect(mock_fs.directory?(path)).to be false }
      end

      describe 'with a qualified path to a directory' do
        let(:path) do
          File.join(
            '..',
            File.split(mock_fs.root_path).last,
            'root_dir',
            'child_dir'
          )
        end

        it { expect(mock_fs.directory?(path)).to be true }
      end

      describe 'with a qualified path to a file' do
        let(:path) do
          File.join(
            '..',
            File.split(mock_fs.root_path).last,
            'root_dir',
            'child_file.txt'
          )
        end

        it { expect(mock_fs.directory?(path)).to be false }
      end

      describe 'with a relative path to a directory' do
        let(:path) { File.join('root_dir', 'child_dir') }

        it { expect(mock_fs.directory?(path)).to be true }
      end

      describe 'with a relative path to a file' do
        let(:path) { File.join('root_dir', 'child_file.txt') }

        it { expect(mock_fs.directory?(path)).to be false }
      end
    end
  end

  describe '#each_file' do
    deferred_examples 'should return or yield the matching file names' do
      describe 'without a block' do
        it { expect(mock_fs.each_file(pattern)).to be_a Enumerator }

        it { expect(mock_fs.each_file(pattern).to_a).to be == matching }
      end

      describe 'with a block' do
        it { expect(mock_fs.each_file(pattern) { nil }).to be nil }

        it 'should yield the matching file names' do # rubocop:disable RSpec/ExampleLength
          expect { |block| mock_fs.each_file(pattern, &block) }.then \
          do |expectation|
            if matching.empty?
              expectation.not_to(yield_control)
            else
              expectation.to yield_successive_args(*matching)
            end
          end
        end
      end
    end

    let(:pattern)  { '**/*.txt' }
    let(:matching) { [] }

    it 'should define the method' do
      expect(mock_fs).to respond_to(:each_file).with(1).argument.and_a_block
    end

    include_deferred 'should return or yield the matching file names'

    wrap_deferred 'when initialized with files' do
      describe 'with a pattern that does not match any files' do
        let(:pattern) { '*.xml' }

        include_deferred 'should return or yield the matching file names'
      end

      describe 'with a globbed pattern' do
        let(:pattern) { '*.txt' }
        let(:matching) do
          %w[root_file.txt]
            .map { |file_name| File.join(mock_fs.root_path, file_name) }
        end

        include_deferred 'should return or yield the matching file names'
      end

      describe 'with a globbed pattern with fixed segments' do
        let(:pattern) { File.join('root_dir', '*.txt') }
        let(:matching) do
          [File.join('root_dir', 'child_file.txt')]
            .map { |file_name| File.join(mock_fs.root_path, file_name) }
        end

        include_deferred 'should return or yield the matching file names'
      end

      describe 'with a recursive globbed pattern' do
        let(:pattern) { File.join('**', '*.txt') }
        let(:matching) do
          [
            File.join('root_dir', 'child_file.txt'),
            'root_file.txt'
          ]
            .map { |file_name| File.join(mock_fs.root_path, file_name) }
        end

        include_deferred 'should return or yield the matching file names'
      end
    end
  end

  describe '#file?' do
    it 'should define the method' do
      expect(mock_fs).to respond_to(:file?).with(1).argument
    end

    it 'should define the aliased method' do
      expect(mock_fs)
        .to have_aliased_method(:file?)
        .as(:file_exists?)
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'path')
      end

      it 'should raise an exception' do
        expect { mock_fs.file?(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('name', as: 'path')
      end

      it 'should raise an exception' do
        expect { mock_fs.file?(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'path')
      end

      it 'should raise an exception' do
        expect { mock_fs.file?('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an invalid absolute path' do
      let(:path) { '/invalid-absolute-path.txt' }

      it { expect(mock_fs.file?(path)).to be false }
    end

    describe 'with an invalid qualified path' do
      let(:path) { '../invalid-qualified-path.txt' }

      it { expect(mock_fs.file?(path)).to be false }
    end

    describe 'with an invalid relative path' do
      let(:path) { 'invalid-relative-path.txt' }

      it { expect(mock_fs.file?(path)).to be false }
    end

    wrap_deferred 'when initialized with files' do
      describe 'with an absolute path to a directory' do
        let(:path) do
          File.join(mock_fs.root_path, 'root_dir', 'child_dir')
        end

        it { expect(mock_fs.file?(path)).to be false }
      end

      describe 'with an absolute path to a file' do
        let(:path) do
          File.join(mock_fs.root_path, 'root_dir', 'child_file.txt')
        end

        it { expect(mock_fs.file?(path)).to be true }
      end

      describe 'with a qualified path to a directory' do
        let(:path) do
          File.join(
            '..',
            File.split(mock_fs.root_path).last,
            'root_dir',
            'child_dir'
          )
        end

        it { expect(mock_fs.file?(path)).to be false }
      end

      describe 'with a qualified path to a file' do
        let(:path) do
          File.join(
            '..',
            File.split(mock_fs.root_path).last,
            'root_dir',
            'child_file.txt'
          )
        end

        it { expect(mock_fs.file?(path)).to be true }
      end

      describe 'with a relative path to a directory' do
        let(:path) { File.join('root_dir', 'child_dir') }

        it { expect(mock_fs.file?(path)).to be false }
      end

      describe 'with a relative path to a file' do
        let(:path) { File.join('root_dir', 'child_file.txt') }

        it { expect(mock_fs.file?(path)).to be true }
      end
    end
  end

  describe '#files' do
    include_examples 'should define reader', :files, {}

    wrap_deferred 'when initialized with files' do
      it { expect(mock_fs.files).to be == files }
    end
  end

  describe '#read_file' do
    it { expect(mock_fs).to respond_to(:read_file).with(1).argument }

    it 'should define the aliased method' do
      expect(mock_fs).to have_aliased_method(:read_file).as(:read)
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: :file)
      end

      it 'should raise an exception' do
        expect { mock_fs.read_file(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        'file is not a String or IO stream'
      end

      it 'should raise an exception' do
        expect { mock_fs.read_file(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: :file)
      end

      it 'should raise an exception' do
        expect { mock_fs.read_file('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an IO stream' do
      let(:stream) { StringIO.new('Greetings, programs!') }

      it { expect(mock_fs.read_file(stream)).to be == stream.string }
    end

    describe 'with a mock Tempfile' do
      let(:tempfile) { described_class::MockTempfile.new('/path/to/file') }

      it { expect(mock_fs.read_file(tempfile)).to be == '' }

      context 'when the tempfile has contents' do
        let(:contents) { 'Contents of tempfile.' }

        before(:example) do
          tempfile.write(contents)
          tempfile.rewind
        end

        it { expect(mock_fs.read_file(tempfile)).to be == contents }
      end
    end

    describe 'with an invalid absolute path' do
      let(:path) { '/invalid-absolute-path' }
      let(:error_message) do
        full_path = File.expand_path(path)

        "unable to read file #{full_path} - file path is not mocked"
      end

      it 'should raise an exception' do
        expect { mock_fs.read_file(path) }
          .to raise_error described_class::InvalidPathError, error_message
      end
    end

    describe 'with an invalid qualified path' do
      let(:path) { '../invalid-qualified-path' }
      let(:error_message) do
        full_path = File.expand_path(path)

        "unable to read file #{full_path} - file path is not mocked"
      end

      it 'should raise an exception' do
        expect { mock_fs.read_file(path) }
          .to raise_error described_class::InvalidPathError, error_message
      end
    end

    describe 'with an invalid relative path' do
      let(:path) { 'invalid-relative-path' }
      let(:error_message) do
        full_path = File.expand_path(path)

        "unable to read file #{full_path} - mock file does not exist"
      end

      it 'should raise an exception' do
        expect { mock_fs.read_file(path) }
          .to raise_error described_class::InvalidPathError, error_message
      end
    end

    wrap_deferred 'when initialized with files' do
      describe 'with an absolute path to a directory' do
        let(:path) do
          File.join(mock_fs.root_path, 'root_dir', 'child_dir')
        end
        let(:error_message) do
          full_path = File.expand_path(path)

          "unable to read file #{full_path} - path is a mock directory"
        end

        it 'should raise an exception' do
          expect { mock_fs.read_file(path) }
            .to raise_error described_class::InvalidPathError, error_message
        end
      end

      describe 'with an absolute path to a file' do
        let(:path) do
          File.join(mock_fs.root_path, 'root_dir', 'child_file.txt')
        end
        let(:expected) { 'Child File' }

        it { expect(mock_fs.read_file(path)).to be == expected }
      end

      describe 'with a qualified path to a directory' do
        let(:path) do
          File.join(
            '..',
            File.split(mock_fs.root_path).last,
            'root_dir',
            'child_dir'
          )
        end
        let(:error_message) do
          full_path = File.expand_path(path)

          "unable to read file #{full_path} - path is a mock directory"
        end

        it 'should raise an exception' do
          expect { mock_fs.read_file(path) }
            .to raise_error described_class::InvalidPathError, error_message
        end
      end

      describe 'with a qualified path to a file' do
        let(:path) do
          File.join(
            '..',
            File.split(mock_fs.root_path).last,
            'root_dir',
            'child_file.txt'
          )
        end
        let(:expected) { 'Child File' }

        it { expect(mock_fs.read_file(path)).to be == expected }
      end

      describe 'with a relative path to a directory' do
        let(:path) { File.join('root_dir', 'child_dir') }
        let(:error_message) do
          full_path = File.expand_path(path)

          "unable to read file #{full_path} - path is a mock directory"
        end

        it 'should raise an exception' do
          expect { mock_fs.read_file(path) }
            .to raise_error described_class::InvalidPathError, error_message
        end
      end

      describe 'with a relative path to a file' do
        let(:path) { File.join('root_dir', 'child_file.txt') }
        let(:expected) { 'Child File' }

        it { expect(mock_fs.read_file(path)).to be == expected }
      end
    end
  end

  describe '#root_path' do
    include_examples 'should define reader', :root_path, Dir.pwd

    context 'when initialized with root_path: value' do
      let(:root_path) { __dir__ }
      let(:options)   { super().merge(root_path:) }

      it { expect(mock_fs.root_path).to be == __dir__ }
    end
  end

  describe '#tempfiles' do
    include_examples 'should define reader', :tempfiles, []
  end

  describe '#with_tempfile' do
    let(:contents) { "Greetings, programs!\n" }

    it 'should define the method' do
      expect(mock_fs)
        .to respond_to(:with_tempfile)
        .with(0).arguments
        .and_a_block
    end

    it 'should yield the file object' do
      expect { |block| mock_fs.with_tempfile(&block) }
        .to yield_with_args(an_instance_of(described_class::MockTempfile))
    end

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

    it { expect(mock_fs).to respond_to(:write_file).with(2).arguments }

    it 'should define the aliased method' do
      expect(mock_fs).to have_aliased_method(:write_file).as(:write)
    end

    describe 'with data: nil' do
      let(:data)   { nil }
      let(:stream) { StringIO.new }

      it 'should not write to the stream' do
        expect { mock_fs.write_file(stream, data) }
          .not_to change(stream, :string)
      end
    end

    describe 'with data: an Object' do
      let(:data)   { Object.new.freeze }
      let(:stream) { StringIO.new }

      it 'should write the object to the stream' do
        expect { mock_fs.write_file(stream, data) }
          .to change(stream, :string)
          .to be == data.inspect
      end
    end

    describe 'with data: an empty String' do
      let(:data)   { '' }
      let(:stream) { StringIO.new }

      it 'should not write to the stream' do
        expect { mock_fs.write_file(stream, data) }
          .not_to change(stream, :string)
      end
    end

    describe 'with file: nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: :file)
      end

      it 'should raise an exception' do
        expect { mock_fs.write_file(nil, data) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with file: an Object' do
      let(:error_message) do
        'file is not a String or IO stream'
      end

      it 'should raise an exception' do
        expect { mock_fs.write_file(Object.new.freeze, data) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with file: an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: :file)
      end

      it 'should raise an exception' do
        expect { mock_fs.write_file('', data) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with file: an IO stream' do
      let(:stream) { StringIO.new }

      it 'should write the data to the stream' do
        expect { mock_fs.write_file(stream, data) }
          .to change(stream, :string)
          .to be == data
      end
    end

    describe 'with file: a mock Tempfile' do
      let(:tempfile) { described_class::MockTempfile.new('/path/to/file') }

      it 'should write the data to the tempfile' do
        expect { mock_fs.write_file(tempfile, data) }
          .to change(tempfile, :string)
          .to be == data
      end
    end

    describe 'with an absolute path' do
      let(:directory) do
        File.join(mock_fs.root_path, 'root_dir')
      end
      let(:path) do
        File.join(directory, file_name)
      end

      it 'should write the data to a new mock file', :aggregate_failures do
        mock_fs.write_file(path, data)

        mock = mock_fs.files.dig('root_dir', file_name)

        expect(mock).to be_a(StringIO)
        expect(mock.string).to be == data
      end

      context 'when the directory is not mocked' do
        let(:directory) do
          File.expand_path(File.join(Cuprum::Cli.gem_path, '..', 'other_dir'))
        end
        let(:error_message) do
          full_path = File.expand_path(path)

          "unable to write file #{full_path} - file path is not mocked"
        end

        it 'should raise an exception' do
          expect { mock_fs.write_file(path, data) }
            .to raise_error described_class::InvalidPathError, error_message
        end
      end

      wrap_deferred 'when initialized with files' do
        context 'when the path is a directory' do
          let(:path) do
            File.join(directory, 'child_dir')
          end
          let(:error_message) do
            full_path = File.expand_path(path)

            "unable to write file #{full_path} - path is a mock directory"
          end

          it 'should raise an exception' do
            expect { mock_fs.write_file(path, data) }
              .to raise_error described_class::InvalidPathError, error_message
          end
        end

        context 'when the path includes a file' do
          let(:directory) do
            super()
              .split(File::SEPARATOR)
              .then { |ary| File.join(*ary[...-1], 'root_file.txt') }
          end
          let(:error_message) do
            full_path = File.expand_path(path)

            "unable to write file #{full_path} - root_file.txt is a mock file"
          end

          it 'should raise an exception' do
            expect { mock_fs.write_file(path, data) }
              .to raise_error described_class::InvalidPathError, error_message
          end
        end

        context 'when the file already exists' do
          let(:file_name) { 'child_file.txt' }

          it 'should replace the contents of the file', :aggregate_failures do
            mock_fs.write_file(path, data)

            mock = mock_fs.files.dig('root_dir', file_name)

            expect(mock).to be_a(StringIO)
            expect(mock.string).to be == data
          end
        end
      end
    end

    describe 'with a qualified path' do
      let(:directory) do
        File.join('..', File.split(mock_fs.root_path).last, 'root_dir')
      end
      let(:path) do
        File.expand_path(File.join(mock_fs.root_path, directory, file_name))
      end

      it 'should write the data to a new mock file', :aggregate_failures do
        mock_fs.write_file(path, data)

        mock = mock_fs.files.dig('root_dir', file_name)

        expect(mock).to be_a(StringIO)
        expect(mock.string).to be == data
      end

      context 'when the directory is not mocked' do
        let(:directory) do
          File.join('..', 'other_dir', 'root_dir')
        end
        let(:error_message) do
          full_path = File.expand_path(path)

          "unable to write file #{full_path} - file path is not mocked"
        end

        it 'should raise an exception' do
          expect { mock_fs.write_file(path, data) }
            .to raise_error described_class::InvalidPathError, error_message
        end
      end

      wrap_deferred 'when initialized with files' do
        context 'when the path is a directory' do
          let(:path) do
            File.join(directory, 'child_dir')
          end
          let(:error_message) do
            full_path = File.expand_path(path)

            "unable to write file #{full_path} - path is a mock directory"
          end

          it 'should raise an exception' do
            expect { mock_fs.write_file(path, data) }
              .to raise_error described_class::InvalidPathError, error_message
          end
        end

        context 'when the path includes a file' do
          let(:directory) do
            super()
              .split(File::SEPARATOR)
              .then { |ary| File.join(*ary[...-1], 'root_file.txt') }
          end
          let(:error_message) do
            full_path = File.expand_path(path)

            "unable to write file #{full_path} - root_file.txt is a mock file"
          end

          it 'should raise an exception' do
            expect { mock_fs.write_file(path, data) }
              .to raise_error described_class::InvalidPathError, error_message
          end
        end

        context 'when the file already exists' do
          let(:file_name) { 'child_file.txt' }

          it 'should replace the contents of the file', :aggregate_failures do
            mock_fs.write_file(path, data)

            mock = mock_fs.files.dig('root_dir', file_name)

            expect(mock).to be_a(StringIO)
            expect(mock.string).to be == data
          end
        end
      end
    end

    describe 'with a relative path' do
      let(:directory) { 'root_dir' }
      let(:path) do
        File.expand_path(File.join(mock_fs.root_path, directory, file_name))
      end

      it 'should write the data to a new mock file', :aggregate_failures do
        mock_fs.write_file(path, data)

        mock = mock_fs.files.dig('root_dir', file_name)

        expect(mock).to be_a(StringIO)
        expect(mock.string).to be == data
      end

      wrap_deferred 'when initialized with files' do
        context 'when the path is a directory' do
          let(:path) do
            File.join(directory, 'child_dir')
          end
          let(:error_message) do
            full_path = File.expand_path(path)

            "unable to write file #{full_path} - path is a mock directory"
          end

          it 'should raise an exception' do
            expect { mock_fs.write_file(path, data) }
              .to raise_error described_class::InvalidPathError, error_message
          end
        end

        context 'when the path includes a file' do
          let(:directory) do
            super()
              .split(File::SEPARATOR)
              .then { |ary| File.join(*ary[...-1], 'root_file.txt') }
          end
          let(:error_message) do
            full_path = File.expand_path(path)

            "unable to write file #{full_path} - root_file.txt is a mock file"
          end

          it 'should raise an exception' do
            expect { mock_fs.write_file(path, data) }
              .to raise_error described_class::InvalidPathError, error_message
          end
        end

        context 'when the file already exists' do
          let(:file_name) { 'child_file.txt' }

          it 'should replace the contents of the file', :aggregate_failures do
            mock_fs.write_file(path, data)

            mock = mock_fs.files.dig('root_dir', file_name)

            expect(mock).to be_a(StringIO)
            expect(mock.string).to be == data
          end
        end
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
