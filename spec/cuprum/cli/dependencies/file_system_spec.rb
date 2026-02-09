# frozen_string_literal: true

require 'fileutils'
require 'securerandom'
require 'stringio'

require 'cuprum/cli/dependencies/file_system'

RSpec.describe Cuprum::Cli::Dependencies::FileSystem do
  subject(:file_system) { described_class.new(**options) }

  let(:options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:root_path)
    end
  end

  describe '#directory?' do
    it 'should define the method' do
      expect(file_system).to respond_to(:directory?).with(1).argument
    end

    it 'should define the aliased method' do
      expect(file_system)
        .to have_aliased_method(:directory?)
        .as(:directory_exists?)
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'path')
      end

      it 'should raise an exception' do
        expect { file_system.directory?(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('name', as: 'path')
      end

      it 'should raise an exception' do
        expect { file_system.directory?(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'path')
      end

      it 'should raise an exception' do
        expect { file_system.directory?('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an invalid absolute path' do
      let(:path) { '/invalid-absolute-path' }

      it { expect(file_system.directory?(path)).to be false }
    end

    describe 'with an invalid qualified path' do
      let(:path) { '../invalid-qualified-path' }

      it { expect(file_system.directory?(path)).to be false }
    end

    describe 'with an invalid relative path' do
      let(:path) { 'invalid-relative-path' }

      it { expect(file_system.directory?(path)).to be false }
    end

    describe 'with an absolute path to a directory' do
      let(:path) do
        File.join(Cuprum::Cli.gem_path, 'spec', 'cuprum', 'cli')
      end

      it { expect(file_system.directory?(path)).to be true }
    end

    describe 'with an absolute path to a file' do
      let(:path) do
        File.join(Cuprum::Cli.gem_path, 'spec', 'spec_helper.rb')
      end

      it { expect(file_system.directory?(path)).to be false }
    end

    describe 'with a qualified path to a directory' do
      let(:path) do
        File.join(
          '..',
          File.split(Cuprum::Cli.gem_path).last,
          'spec',
          'cuprum',
          'cli'
        )
      end

      it { expect(file_system.directory?(path)).to be true }
    end

    describe 'with a qualified path to a file' do
      let(:path) do
        File.join(
          '..',
          File.split(Cuprum::Cli.gem_path).last,
          'spec',
          'spec_helper.rb'
        )
      end

      it { expect(file_system.directory?(path)).to be false }
    end

    describe 'with a relative path to a directory' do
      let(:path) { File.join('spec', 'cuprum', 'cli') }

      it { expect(file_system.directory?(path)).to be true }
    end

    describe 'with a relative path to a file' do
      let(:path) { File.join('spec', 'spec_helper.rb') }

      it { expect(file_system.directory?(path)).to be false }
    end

    context 'when initialized with root_path: value' do
      let(:root_path) { File.join(Cuprum::Cli.gem_path, 'spec', 'cuprum') }
      let(:options)   { super().merge(root_path:) }

      describe 'with a qualified path to a directory' do
        let(:path) { File.join('..', 'cuprum', 'cli') }

        it { expect(file_system.directory?(path)).to be true }
      end

      describe 'with a qualified path to a file' do
        let(:path) { File.join('..', 'cuprum', 'cli_spec.rb') }

        it { expect(file_system.directory?(path)).to be false }
      end

      describe 'with a relative path to a directory' do
        let(:path) { 'cli' }

        it { expect(file_system.directory?(path)).to be true }
      end

      describe 'with a relative path to a file' do
        let(:path) { 'cli_spec.rb' }

        it { expect(file_system.directory?(path)).to be false }
      end
    end
  end

  describe '#each_file' do
    let(:pattern)  { '**/*.rb' }
    let(:matching) { [] }

    before(:example) { allow(Dir).to receive(:[]).and_return(matching) }

    it 'should define the method' do
      expect(file_system).to respond_to(:each_file).with(1).argument.and_a_block
    end

    it 'should delegate to Dir#[]' do
      file_system.each_file(pattern) { nil }

      expect(Dir)
        .to have_received(:[])
        .with(File.join(file_system.root_path, pattern))
    end

    context 'when initialized with root_path: value' do
      let(:root_path) { __dir__ }
      let(:options)   { super().merge(root_path:) }

      it 'should delegate to Dir#[]' do
        file_system.each_file(pattern) { nil }

        expect(Dir)
          .to have_received(:[])
          .with(File.join(file_system.root_path, pattern))
      end
    end

    describe 'without a block' do
      it { expect(file_system.each_file(pattern)).to be_a Enumerator }

      it { expect(file_system.each_file(pattern).to_a).to be == matching }

      context 'when there are many matching files' do
        let(:matching) do
          %w[
            /path/to/first.rb
            /path/to/second.rb
            /path/to/third.rb
          ]
        end

        it { expect(file_system.each_file(pattern).to_a).to be == matching }
      end
    end

    describe 'with a block' do
      it { expect(file_system.each_file(pattern) { nil }).to be nil }

      it 'should not yield any file names' do
        expect { |block| file_system.each_file(pattern, &block) }
          .not_to yield_control
      end

      context 'when there are many matching files' do
        let(:matching) do
          %w[
            /path/to/first.rb
            /path/to/second.rb
            /path/to/third.rb
          ]
        end

        it { expect(file_system.each_file(pattern) { nil }).to be nil }

        it 'should yield each matching file name' do
          expect { |block| file_system.each_file(pattern, &block) }
            .to yield_successive_args(*matching)
        end
      end
    end
  end

  describe '#file?' do
    it 'should define the method' do
      expect(file_system).to respond_to(:file?).with(1).argument
    end

    it 'should define the aliased method' do
      expect(file_system)
        .to have_aliased_method(:file?)
        .as(:file_exists?)
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'path')
      end

      it 'should raise an exception' do
        expect { file_system.file?(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('name', as: 'path')
      end

      it 'should raise an exception' do
        expect { file_system.file?(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'path')
      end

      it 'should raise an exception' do
        expect { file_system.file?('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an invalid absolute path' do
      let(:path) { '/invalid-absolute-path' }

      it { expect(file_system.file?(path)).to be false }
    end

    describe 'with an invalid qualified path' do
      let(:path) { '../invalid-qualified-path' }

      it { expect(file_system.file?(path)).to be false }
    end

    describe 'with an invalid relative path' do
      let(:path) { 'invalid-relative-path' }

      it { expect(file_system.file?(path)).to be false }
    end

    describe 'with an absolute path to a directory' do
      let(:path) do
        File.join(Cuprum::Cli.gem_path, 'spec', 'cuprum', 'cli')
      end

      it { expect(file_system.file?(path)).to be false }
    end

    describe 'with an absolute path to a file' do
      let(:path) do
        File.join(Cuprum::Cli.gem_path, 'spec', 'spec_helper.rb')
      end

      it { expect(file_system.file?(path)).to be true }
    end

    describe 'with a qualified path to a directory' do
      let(:path) do
        File.join(
          '..',
          File.split(Cuprum::Cli.gem_path).last,
          'spec',
          'cuprum',
          'cli'
        )
      end

      it { expect(file_system.file?(path)).to be false }
    end

    describe 'with a qualified path to a file' do
      let(:path) do
        File.join(
          '..',
          File.split(Cuprum::Cli.gem_path).last,
          'spec',
          'spec_helper.rb'
        )
      end

      it { expect(file_system.file?(path)).to be true }
    end

    describe 'with a relative path to a directory' do
      let(:path) { 'spec/cuprum/cli' }

      it { expect(file_system.file?(path)).to be false }
    end

    describe 'with a relative path to a file' do
      let(:path) { 'spec/spec_helper.rb' }

      it { expect(file_system.file?(path)).to be true }
    end

    context 'when initialized with root_path: value' do
      let(:root_path) { File.join(Cuprum::Cli.gem_path, 'spec', 'cuprum') }
      let(:options)   { super().merge(root_path:) }

      describe 'with a qualified path to a directory' do
        let(:path) { File.join('..', 'cuprum', 'cli') }

        it { expect(file_system.file?(path)).to be false }
      end

      describe 'with a qualified path to a file' do
        let(:path) { File.join('..', 'cuprum', 'cli_spec.rb') }

        it { expect(file_system.file?(path)).to be true }
      end

      describe 'with a relative path to a directory' do
        let(:path) { 'cli' }

        it { expect(file_system.file?(path)).to be false }
      end

      describe 'with a relative path to a file' do
        let(:path) { 'cli_spec.rb' }

        it { expect(file_system.file?(path)).to be true }
      end
    end
  end

  describe '#read_file' do
    it { expect(file_system).to respond_to(:read_file).with(1).argument }

    it 'should define the aliased method' do
      expect(file_system).to have_aliased_method(:read_file).as(:read)
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: :file)
      end

      it 'should raise an exception' do
        expect { file_system.read_file(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        'file is not a String or IO stream'
      end

      it 'should raise an exception' do
        expect { file_system.read_file(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: :file)
      end

      it 'should raise an exception' do
        expect { file_system.read_file('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an IO stream' do
      let(:stream) { StringIO.new('Greetings, programs!') }

      it { expect(file_system.read_file(stream)).to be == stream.string }
    end

    describe 'with an invalid absolute path' do
      let(:path) { '/invalid-absolute-path' }

      it 'should raise an exception' do
        expect { file_system.read_file(path) }.to raise_error Errno::ENOENT
      end
    end

    describe 'with an invalid qualified path' do
      let(:path) { '../invalid-qualified-path' }

      it 'should raise an exception' do
        expect { file_system.read_file(path) }.to raise_error Errno::ENOENT
      end
    end

    describe 'with an invalid relative path' do
      let(:path) { 'invalid-relative-path' }

      it 'should raise an exception' do
        expect { file_system.read_file(path) }.to raise_error Errno::ENOENT
      end
    end

    describe 'with an absolute path to a directory' do
      let(:path) do
        File.join(Cuprum::Cli.gem_path, 'spec', 'cuprum', 'cli')
      end

      it 'should raise an exception' do
        expect { file_system.read_file(path) }.to raise_error Errno::EISDIR
      end
    end

    describe 'with an absolute path to a file' do
      let(:contents) { 'Greetings, programs!' }
      let(:path) do
        File.join(Cuprum::Cli.gem_path, 'spec', 'spec_helper.rb')
      end

      before(:example) do
        allow(File).to receive(:read).and_wrap_original do |original, path|
          original.call(path) # Ensure path is valid.

          contents
        end
      end

      it { expect(file_system.read_file(path)).to be == contents }
    end

    describe 'with a qualified path to a directory' do
      let(:path) do
        File.join(
          '..',
          File.split(Cuprum::Cli.gem_path).last,
          'spec',
          'cuprum',
          'cli'
        )
      end

      it 'should raise an exception' do
        expect { file_system.read_file(path) }.to raise_error Errno::EISDIR
      end
    end

    describe 'with a qualified path to a file' do
      let(:contents) { 'Greetings, programs!' }
      let(:path) do
        File.join(
          '..',
          File.split(Cuprum::Cli.gem_path).last,
          'spec',
          'spec_helper.rb'
        )
      end

      before(:example) do
        allow(File).to receive(:read).and_wrap_original do |original, path|
          original.call(path) # Ensure path is valid.

          contents
        end
      end

      it { expect(file_system.read_file(path)).to be == contents }
    end

    describe 'with a relative path to a directory' do
      let(:path) { 'spec/cuprum/cli' }

      it 'should raise an exception' do
        expect { file_system.read_file(path) }.to raise_error Errno::EISDIR
      end
    end

    describe 'with a relative path to a file' do
      let(:contents) { 'Greetings, programs!' }
      let(:path)     { 'spec/spec_helper.rb' }

      before(:example) do
        allow(File).to receive(:read).and_wrap_original do |original, path|
          original.call(path) # Ensure path is valid.

          contents
        end
      end

      it { expect(file_system.read_file(path)).to be == contents }
    end

    context 'when initialized with root_path: value' do
      let(:root_path) { File.join(Cuprum::Cli.gem_path, 'spec', 'cuprum') }
      let(:options)   { super().merge(root_path:) }

      describe 'with a qualified path to a directory' do
        let(:path) { File.join('..', 'cuprum', 'cli') }

        it 'should raise an exception' do
          expect { file_system.read_file(path) }.to raise_error Errno::EISDIR
        end
      end

      describe 'with a qualified path to a file' do
        let(:contents) { 'Greetings, programs!' }
        let(:path)     { File.join('..', 'cuprum', 'cli_spec.rb') }

        before(:example) do
          allow(File).to receive(:read).and_wrap_original do |original, path|
            original.call(path) # Ensure path is valid.

            contents
          end
        end

        it { expect(file_system.read_file(path)).to be == contents }
      end

      describe 'with a relative path to a directory' do
        let(:path) { 'cli' }

        it 'should raise an exception' do
          expect { file_system.read_file(path) }.to raise_error Errno::EISDIR
        end
      end

      describe 'with a relative path to a file' do
        let(:contents) { 'Greetings, programs!' }
        let(:path)     { 'cli_spec.rb' }

        before(:example) do
          allow(File).to receive(:read).and_wrap_original do |original, path|
            original.call(path) # Ensure path is valid.

            contents
          end
        end

        it { expect(file_system.read_file(path)).to be == contents }
      end
    end
  end

  describe '#root_path' do
    include_examples 'should define reader', :root_path, Dir.pwd

    context 'when initialized with root_path: value' do
      let(:root_path) { __dir__ }
      let(:options)   { super().merge(root_path:) }

      it { expect(file_system.root_path).to be == __dir__ }
    end
  end

  describe '#with_tempfile' do
    it 'should define the method' do
      expect(file_system)
        .to respond_to(:with_tempfile)
        .with(0).arguments
        .and_a_block
    end

    it 'should yield the file object' do
      expect { |block| file_system.with_tempfile(&block) }
        .to yield_with_args(an_instance_of(File))
    end

    it 'should clean up the tempfile', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      path = nil

      file_system.with_tempfile do |file|
        path = file.path

        expect(File.exist?(path)).to be true
      end

      expect(File.exist?(path)).to be false
    end
  end

  describe '#write_file' do
    let(:data) { "Greetings, programs!\n" }

    before(:context) do # rubocop:disable RSpec/BeforeAfterAll
      # :nocov:
      tmp_path = File.join(Cuprum::Cli.gem_path, 'tmp')

      next if Dir.exist?(tmp_path)

      FileUtils.mkdir(tmp_path)
      # :nocov:
    end

    it { expect(file_system).to respond_to(:write_file).with(2).arguments }

    it 'should define the aliased method' do
      expect(file_system).to have_aliased_method(:write_file).as(:write)
    end

    describe 'with data: nil' do
      let(:data)   { nil }
      let(:stream) { StringIO.new }

      it 'should not write to the stream' do
        expect { file_system.write_file(stream, data) }
          .not_to change(stream, :string)
      end
    end

    describe 'with data: an Object' do
      let(:data)   { Object.new.freeze }
      let(:stream) { StringIO.new }

      it 'should write the object to the stream' do
        expect { file_system.write_file(stream, data) }
          .to change(stream, :string)
          .to be == data.inspect
      end
    end

    describe 'with data: an empty String' do
      let(:data)   { '' }
      let(:stream) { StringIO.new }

      it 'should not write to the stream' do
        expect { file_system.write_file(stream, data) }
          .not_to change(stream, :string)
      end
    end

    describe 'with file: nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: :file)
      end

      it 'should raise an exception' do
        expect { file_system.write_file(nil, data) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with file: an Object' do
      let(:error_message) do
        'file is not a String or IO stream'
      end

      it 'should raise an exception' do
        expect { file_system.write_file(Object.new.freeze, data) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with file: an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: :file)
      end

      it 'should raise an exception' do
        expect { file_system.write_file('', data) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with file: an IO stream' do
      let(:stream) { StringIO.new }

      it 'should write the data to the stream' do
        expect { file_system.write_file(stream, data) }
          .to change(stream, :string)
          .to be == data
      end
    end

    describe 'with an absolute path' do
      let(:directory) do
        File.expand_path(File.join(Cuprum::Cli.gem_path, 'tmp'))
      end
      let(:path) do
        File.join(directory, "#{SecureRandom.uuid}.txt")
      end

      around(:example) do |example|
        example.call
      ensure
        FileUtils.remove_file(path, force: true)
      end

      it 'should write the data to a new file' do
        file_system.write_file(path, data)

        expect(File.read(path)).to be == data
      end

      context 'when the directory is not writeable' do
        let(:directory) { File.join(super(), 'invalid_directory') }

        it 'should raise an exception' do
          expect { file_system.write_file(path, data) }
            .to raise_error Errno::ENOENT
        end
      end

      context 'when the file already exists' do
        before(:example) do
          File.write(path, "Existing contents...\n")
        end

        it 'should replace the contents of the file' do
          file_system.write_file(path, data)

          expect(File.read(path)).to be == data
        end
      end
    end

    describe 'with a qualified path' do
      let(:directory) do
        File.join(
          '..',
          File.split(Cuprum::Cli.gem_path).last,
          'tmp'
        )
      end
      let(:path) do
        File.join(directory, "#{SecureRandom.uuid}.txt")
      end

      around(:example) do |example|
        example.call
      ensure
        FileUtils.remove_file(path, force: true)
      end

      it 'should write the data to a new file' do
        file_system.write_file(path, data)

        expect(File.read(path)).to be == data
      end

      context 'when the directory is not writeable' do
        let(:directory) { File.join(super(), 'invalid_directory') }

        it 'should raise an exception' do
          expect { file_system.write_file(path, data) }
            .to raise_error Errno::ENOENT
        end
      end

      context 'when the file already exists' do
        before(:example) do
          File.write(path, "Existing contents...\n")
        end

        it 'should replace the contents of the file' do
          file_system.write_file(path, data)

          expect(File.read(path)).to be == data
        end
      end
    end

    describe 'with a relative path' do
      let(:directory) { 'tmp' }
      let(:path) do
        File.join(directory, "#{SecureRandom.uuid}.txt")
      end

      around(:example) do |example|
        example.call
      ensure
        FileUtils.remove_file(path, force: true)
      end

      it 'should write the data to a new file' do
        file_system.write_file(path, data)

        expect(File.read(path)).to be == data
      end

      context 'when the directory is not writeable' do
        let(:directory) { File.join(super(), 'invalid_directory') }

        it 'should raise an exception' do
          expect { file_system.write_file(path, data) }
            .to raise_error Errno::ENOENT
        end
      end

      context 'when the file already exists' do
        before(:example) do
          File.write(path, "Existing contents...\n")
        end

        it 'should replace the contents of the file' do
          file_system.write_file(path, data)

          expect(File.read(path)).to be == data
        end
      end
    end

    context 'when initialized with root_path: value' do
      let(:root_path) do
        File.join(Cuprum::Cli.gem_path, 'tmp', 'files')
      end
      let(:nested_path) do
        File.join(root_path, 'nested')
      end
      let(:options) { super().merge(root_path:) }

      around(:example) do |example|
        FileUtils.mkdir(root_path)
        FileUtils.mkdir(nested_path)

        example.call
      ensure
        FileUtils.rm_rf(root_path)
      end

      describe 'with a qualified path' do
        let(:directory) do
          File.join('..', '..', 'tmp', 'files')
        end
        let(:path) do
          File.join(directory, "#{SecureRandom.uuid}.txt")
        end
        let(:expanded_path) do
          File.expand_path(File.join(root_path, path))
        end

        it 'should write the data to a new file' do
          file_system.write_file(path, data)

          expect(File.read(expanded_path)).to be == data
        end
      end

      describe 'with a relative path' do
        let(:path) do
          File.join('nested', "#{SecureRandom.uuid}.txt")
        end
        let(:expanded_path) do
          File.expand_path(File.join(root_path, path))
        end

        it 'should write the data to a new file' do
          file_system.write_file(path, data)

          expect(File.read(expanded_path)).to be == data
        end
      end
    end
  end
end
