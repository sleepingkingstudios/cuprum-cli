# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'cuprum/cli/rspec/deferred/dependencies'

module Cuprum::Cli::RSpec::Deferred::Dependencies
  # Deferred examples for testing the FileSystem dependency.
  module FileSystemExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_examples 'should implement the file_system dependency' do
      describe '#create_directory', :writeable_root_path do
        let(:base_path) { nil }
        let(:path)      { nil }

        include_deferred 'with valid file paths'

        include_deferred 'when created directories are cleaned up'

        it 'should define the method' do
          expect(subject)
            .to respond_to(:create_directory)
            .with(1).argument
            .and_keywords(:recursive)
        end

        it 'should define the aliased method' do
          expect(subject)
            .to have_aliased_method(:create_directory)
            .as(:make_directory)
        end

        describe 'with nil' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: :path)
          end

          it 'should raise an exception' do
            expect { subject.create_directory(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) do
            tools.assertions.error_message_for('name', as: :path)
          end

          it 'should raise an exception' do
            expect { subject.create_directory(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty String' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: :path)
          end

          it 'should raise an exception' do
            expect { subject.create_directory('') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an absolute path' do
          let(:base_path) { absolute_directory_path }
          let(:path)      { File.join(base_path, 'custom_dir') }

          it { expect(subject.create_directory(path)).to be == path }

          it 'should create the directory' do
            expect { subject.create_directory(path) }.to(
              change { subject.directory?(path) }.to(be true)
            )
          end

          describe 'with a multi-segment path' do
            let(:path) { File.join(base_path, 'custom_dir/inner/path') }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryNotFoundError
            end
            let(:error_message) do
              "unable to create directory #{path} - directory not found"
            end

            it 'should raise an exception' do
              expect { subject.create_directory(path) }
                .to raise_error(error_class, error_message)
            end

            describe 'with recursive: true' do
              it 'should return the path' do
                expect(subject.create_directory(path, recursive: true))
                  .to be == path
              end

              it 'should create the directory' do
                expect { subject.create_directory(path, recursive: true) }.to(
                  change { subject.directory?(path) }.to(be true)
                )
              end

              context 'when the directory already exists' do
                before(:example) do
                  subject.create_directory(path, recursive: true)
                end

                it { expect(subject.create_directory(path)).to be == path }
              end

              context 'when the path includes a file' do
                let(:error_class) do
                  Cuprum::Cli::Dependencies::FileSystem::DirectoryIsAFileError
                end
                let(:error_message) do
                  "unable to create directory #{path} - directory is a file"
                end
                let(:file_path) { File.join(base_path, 'custom_dir') }

                before(:example) do
                  subject.write_file(file_path, '')
                end

                include_deferred 'when created files are cleaned up'

                it 'should raise an exception' do
                  expect { subject.create_directory(path, recursive: true) }
                    .to raise_error(error_class, error_message)
                end

                it 'should not create the directory' do
                  subject.create_directory(path, recursive: true)
                rescue error_class
                  expect(subject.directory?(path)).to be false
                end
              end
            end
          end

          context 'when the directory already exists' do
            before(:example) { subject.create_directory(path) }

            it { expect(subject.create_directory(path)).to be == path }
          end

          context 'when the path includes a file' do
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryIsAFileError
            end
            let(:error_message) do
              "unable to create directory #{path} - directory is a file"
            end

            before(:example) { subject.write_file(path, '') }

            include_deferred 'when created files are cleaned up'

            it 'should raise an exception' do
              expect { subject.create_directory(path) }
                .to raise_error(error_class, error_message)
            end

            it 'should not create the directory' do
              subject.create_directory(path)
            rescue error_class
              expect(subject.directory?(path)).to be false
            end
          end
        end

        describe 'with a qualified path' do
          let(:base_path) { qualified_directory_path }
          let(:path)      { File.join(base_path, 'custom_dir') }

          it { expect(subject.create_directory(path)).to be == path }

          describe 'with a multi-segment path' do
            let(:path) { File.join(base_path, 'custom_dir/inner/path') }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryNotFoundError
            end
            let(:error_message) do
              "unable to create directory #{path} - directory not found"
            end

            it 'should raise an exception' do
              expect { subject.create_directory(path) }
                .to raise_error(error_class, error_message)
            end

            describe 'with recursive: true' do
              it 'should return the path' do
                expect(subject.create_directory(path, recursive: true))
                  .to be == path
              end

              it 'should create the directory' do
                expect { subject.create_directory(path, recursive: true) }.to(
                  change { subject.directory?(path) }.to(be true)
                )
              end

              context 'when the directory already exists' do
                before(:example) do
                  subject.create_directory(path, recursive: true)
                end

                it { expect(subject.create_directory(path)).to be == path }
              end

              context 'when the path includes a file' do
                let(:error_class) do
                  Cuprum::Cli::Dependencies::FileSystem::DirectoryIsAFileError
                end
                let(:error_message) do
                  "unable to create directory #{path} - directory is a file"
                end
                let(:file_path) { File.join(base_path, 'custom_dir') }

                before(:example) do
                  subject.write_file(file_path, '')
                end

                include_deferred 'when created files are cleaned up'

                it 'should raise an exception' do
                  expect { subject.create_directory(path, recursive: true) }
                    .to raise_error(error_class, error_message)
                end

                it 'should not create the directory' do
                  subject.create_directory(path, recursive: true)
                rescue error_class
                  expect(subject.directory?(path)).to be false
                end
              end
            end
          end

          context 'when the directory already exists' do
            before(:example) { subject.create_directory(path) }

            it { expect(subject.create_directory(path)).to be == path }
          end

          context 'when the path includes a file' do
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryIsAFileError
            end
            let(:error_message) do
              "unable to create directory #{path} - directory is a file"
            end

            before(:example) { subject.write_file(path, '') }

            include_deferred 'when created files are cleaned up'

            it 'should raise an exception' do
              expect { subject.create_directory(path) }
                .to raise_error(error_class, error_message)
            end

            it 'should not create the directory' do
              subject.create_directory(path)
            rescue error_class
              expect(subject.directory?(path)).to be false
            end
          end
        end

        describe 'with a relative path' do
          let(:base_path) { relative_directory_path }
          let(:path)      { File.join(base_path, 'custom_dir') }

          it { expect(subject.create_directory(path)).to be == path }

          describe 'with a multi-segment path' do
            let(:path) { File.join(base_path, 'custom_dir/inner/path') }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryNotFoundError
            end
            let(:error_message) do
              "unable to create directory #{path} - directory not found"
            end

            it 'should raise an exception' do
              expect { subject.create_directory(path) }
                .to raise_error(error_class, error_message)
            end

            describe 'with recursive: true' do
              it 'should return the path' do
                expect(subject.create_directory(path, recursive: true))
                  .to be == path
              end

              it 'should create the directory' do
                expect { subject.create_directory(path, recursive: true) }.to(
                  change { subject.directory?(path) }.to(be true)
                )
              end

              context 'when the directory already exists' do
                before(:example) do
                  subject.create_directory(path, recursive: true)
                end

                it { expect(subject.create_directory(path)).to be == path }
              end

              context 'when the path includes a file' do
                let(:error_class) do
                  Cuprum::Cli::Dependencies::FileSystem::DirectoryIsAFileError
                end
                let(:error_message) do
                  "unable to create directory #{path} - directory is a file"
                end
                let(:file_path) { File.join(base_path, 'custom_dir') }

                before(:example) do
                  subject.write_file(file_path, '')
                end

                include_deferred 'when created files are cleaned up'

                it 'should raise an exception' do
                  expect { subject.create_directory(path, recursive: true) }
                    .to raise_error(error_class, error_message)
                end

                it 'should not create the directory' do
                  subject.create_directory(path, recursive: true)
                rescue error_class
                  expect(subject.directory?(path)).to be false
                end
              end
            end
          end

          context 'when the directory already exists' do
            before(:example) { subject.create_directory(path) }

            it { expect(subject.create_directory(path)).to be == path }
          end

          context 'when the path includes a file' do
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryIsAFileError
            end
            let(:error_message) do
              "unable to create directory #{path} - directory is a file"
            end

            before(:example) { subject.write_file(path, '') }

            include_deferred 'when created files are cleaned up'

            it 'should raise an exception' do
              expect { subject.create_directory(path) }
                .to raise_error(error_class, error_message)
            end

            it 'should not create the directory' do
              subject.create_directory(path)
            rescue error_class
              expect(subject.directory?(path)).to be false
            end
          end
        end

        wrap_deferred 'when initialized with root_path: value' do
          describe 'with a qualified path' do
            let(:base_path) { File.join('..', '..', 'tmp', 'files') }
            let(:path)      { File.join(base_path, 'custom_dir') }

            it { expect(subject.create_directory(path)).to be == path }

            it 'should create the directory' do
              expect { subject.create_directory(path) }.to(
                change { subject.directory?(path) }.to(be true)
              )
            end

            describe 'with a multi-segment path' do
              let(:path) { File.join(base_path, 'custom_dir/inner/path') }

              describe 'with recursive: true' do
                it 'should return the path' do
                  expect(subject.create_directory(path, recursive: true))
                    .to be == path
                end

                it 'should create the directory' do
                  expect { subject.create_directory(path, recursive: true) }.to(
                    change { subject.directory?(path) }.to(be true)
                  )
                end
              end
            end
          end

          describe 'with a relative path' do
            let(:base_path) { 'nested' }
            let(:path)      { File.join(base_path, 'custom_dir') }

            it { expect(subject.create_directory(path)).to be == path }

            it 'should create the directory' do
              expect { subject.create_directory(path) }.to(
                change { subject.directory?(path) }.to(be true)
              )
            end

            describe 'with a multi-segment path' do
              let(:path) { File.join(base_path, 'custom_dir/inner/path') }

              describe 'with recursive: true' do
                it 'should return the path' do
                  expect(subject.create_directory(path, recursive: true))
                    .to be == path
                end

                it 'should create the directory' do
                  expect { subject.create_directory(path, recursive: true) }.to(
                    change { subject.directory?(path) }.to(be true)
                  )
                end
              end
            end
          end
        end
      end

      describe '#directory?' do
        let(:invalid_absolute_path) do
          defined?(super()) ? super() : '/invalid-absolute-path'
        end
        let(:invalid_qualified_path) do
          defined?(super()) ? super() : '../invalid-qualified-path'
        end
        let(:invalid_relative_path) do
          defined?(super()) ? super() : 'invalid-absolute-path'
        end

        include_deferred 'with valid file paths'

        it 'should define the method' do
          expect(subject).to respond_to(:directory?).with(1).argument
        end

        it 'should define the aliased method' do
          expect(subject)
            .to have_aliased_method(:directory?)
            .as(:directory_exists?)
        end

        describe 'with nil' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'path')
          end

          it 'should raise an exception' do
            expect { subject.directory?(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) do
            tools.assertions.error_message_for('name', as: 'path')
          end

          it 'should raise an exception' do
            expect { subject.directory?(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty String' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'path')
          end

          it 'should raise an exception' do
            expect { subject.directory?('') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an invalid absolute path' do
          let(:path) { invalid_absolute_path }

          it { expect(subject.directory?(path)).to be false }
        end

        describe 'with an invalid qualified path' do
          let(:path) { invalid_qualified_path }

          it { expect(subject.directory?(path)).to be false }
        end

        describe 'with an invalid relative path' do
          let(:path) { invalid_relative_path }

          it { expect(subject.directory?(path)).to be false }
        end

        describe 'with an absolute path to a directory' do
          let(:path) { absolute_directory_path }

          it { expect(subject.directory?(path)).to be true }
        end

        describe 'with an absolute path to a file' do
          let(:path) { absolute_file_path }

          it { expect(subject.directory?(path)).to be false }
        end

        describe 'with a qualified path to a directory' do
          let(:path) { qualified_directory_path }

          it { expect(subject.directory?(path)).to be true }
        end

        describe 'with a qualified path to a file' do
          let(:path) { qualified_file_path }

          it { expect(subject.directory?(path)).to be false }
        end

        describe 'with a relative path to a directory' do
          let(:path) { relative_directory_path }

          it { expect(subject.directory?(path)).to be true }
        end

        describe 'with a relative path to a file' do
          let(:path) { relative_file_path }

          it { expect(subject.directory?(path)).to be false }
        end

        wrap_deferred 'when initialized with root_path: value' do
          describe 'with a qualified path to a directory' do
            let(:path) { qualified_directory_path }

            it { expect(subject.directory?(path)).to be true }
          end

          describe 'with a qualified path to a file' do
            let(:path) { qualified_file_path }

            it { expect(subject.directory?(path)).to be false }
          end

          describe 'with a relative path to a directory' do
            let(:path) { relative_directory_path }

            it { expect(subject.directory?(path)).to be true }
          end

          describe 'with a relative path to a file' do
            let(:path) { relative_file_path }

            it { expect(subject.directory?(path)).to be false }
          end
        end
      end

      describe '#each_file' do
        deferred_examples 'should return or yield the matching file names' do
          describe 'without a block' do
            it { expect(subject.each_file(pattern)).to be_a Enumerator }

            it 'should return the matching file names' do
              expect(subject.each_file(pattern).to_a).to be == expected_files
            end
          end

          describe 'with a block' do
            it { expect(subject.each_file(pattern) { nil }).to be nil }

            it 'should yield the matching file names' do
              expect { |block| subject.each_file(pattern, &block) }.then \
              do |expectation|
                if expected_files.empty?
                  expectation.not_to(yield_control)
                else
                  expectation.to yield_successive_args(*expected_files)
                end
              end
            end
          end
        end

        let(:pattern) { '**/*.rb' }
        let(:matching_files) do
          defined?(super()) ? super() : []
        end
        let(:expected_files) { matching_files }

        it 'should define the method' do
          expect(subject)
            .to respond_to(:each_file)
            .with(1).argument
            .and_a_block
        end

        include_deferred 'should return or yield the matching file names'

        wrap_deferred 'with valid file paths' do
          describe 'with a pattern that does not match any files' do
            let(:pattern)        { '*.xml' }
            let(:matching_files) { [] }

            include_deferred 'should return or yield the matching file names'
          end

          describe 'with a globbed pattern' do
            let(:pattern) { '*.txt' }
            let(:expected_files) do
              rxp = /\A\w+\.txt\z/

              matching_files.select do |str|
                str[(1 + subject.root_path.size)..].match?(rxp)
              end
            end

            include_deferred 'should return or yield the matching file names'
          end

          describe 'with a globbed pattern with fixed segments' do
            let(:pattern) { File.join(files_directory, '*.txt') }
            let(:expected_files) do
              rxp = %r{\A#{files_directory}/\w+\.txt\z}

              matching_files.select do |str|
                str[(1 + subject.root_path.size)..].match?(rxp)
              end
            end

            include_deferred 'should return or yield the matching file names'
          end

          describe 'with a recursive globbed pattern' do
            let(:pattern) { File.join('**', '*.txt') }
            let(:expected_files) do
              rxp = /\.txt\z/

              matching_files.select do |str|
                str[(1 + subject.root_path.size)..].match?(rxp)
              end
            end

            include_deferred 'should return or yield the matching file names'
          end
        end
      end

      describe '#file?' do
        let(:invalid_absolute_path) do
          defined?(super()) ? super() : '/invalid-absolute-path'
        end
        let(:invalid_qualified_path) do
          defined?(super()) ? super() : '../invalid-qualified-path'
        end
        let(:invalid_relative_path) do
          defined?(super()) ? super() : 'invalid-absolute-path'
        end

        include_deferred 'with valid file paths'

        it 'should define the method' do
          expect(subject).to respond_to(:file?).with(1).argument
        end

        it 'should define the aliased method' do
          expect(subject)
            .to have_aliased_method(:file?)
            .as(:file_exists?)
        end

        describe 'with nil' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'path')
          end

          it 'should raise an exception' do
            expect { subject.file?(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) do
            tools.assertions.error_message_for('name', as: 'path')
          end

          it 'should raise an exception' do
            expect { subject.file?(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty String' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'path')
          end

          it 'should raise an exception' do
            expect { subject.file?('') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an invalid absolute path' do
          let(:path) { invalid_absolute_path }

          it { expect(subject.file?(path)).to be false }
        end

        describe 'with an invalid qualified path' do
          let(:path) { invalid_qualified_path }

          it { expect(subject.file?(path)).to be false }
        end

        describe 'with an invalid relative path' do
          let(:path) { invalid_relative_path }

          it { expect(subject.file?(path)).to be false }
        end

        describe 'with an absolute path to a directory' do
          let(:path) { absolute_directory_path }

          it { expect(subject.file?(path)).to be false }
        end

        describe 'with an absolute path to a file' do
          let(:path) { absolute_file_path }

          it { expect(subject.file?(path)).to be true }
        end

        describe 'with a qualified path to a directory' do
          let(:path) { qualified_directory_path }

          it { expect(subject.file?(path)).to be false }
        end

        describe 'with a qualified path to a file' do
          let(:path) { qualified_file_path }

          it { expect(subject.file?(path)).to be true }
        end

        describe 'with a relative path to a directory' do
          let(:path) { relative_directory_path }

          it { expect(subject.file?(path)).to be false }
        end

        describe 'with a relative path to a file' do
          let(:path) { relative_file_path }

          it { expect(subject.file?(path)).to be true }
        end

        wrap_deferred 'when initialized with root_path: value' do
          describe 'with a qualified path to a directory' do
            let(:path) { qualified_directory_path }

            it { expect(subject.file?(path)).to be false }
          end

          describe 'with a qualified path to a file' do
            let(:path) { qualified_file_path }

            it { expect(subject.file?(path)).to be true }
          end

          describe 'with a relative path to a directory' do
            let(:path) { relative_directory_path }

            it { expect(subject.file?(path)).to be false }
          end

          describe 'with a relative path to a file' do
            let(:path) { relative_file_path }

            it { expect(subject.file?(path)).to be true }
          end
        end
      end

      describe '#read_file', replace_file_contents: true do
        let(:invalid_absolute_path) do
          defined?(super()) ? super() : '/invalid-absolute-path'
        end
        let(:invalid_qualified_path) do
          defined?(super()) ? super() : '../invalid-qualified-path'
        end
        let(:invalid_relative_path) do
          defined?(super()) ? super() : 'invalid-relative-path'
        end
        let(:expected_contents) do
          path = self.path

          if path.start_with?('.')
            path = File.expand_path(File.join(subject.root_path, path))
          end

          path = path.sub(%r{\A#{subject.root_path}/?}, '')

          "Contents of #{path}"
        end

        it { expect(subject).to respond_to(:read_file).with(1).argument }

        it 'should define the aliased method' do
          expect(subject).to have_aliased_method(:read_file).as(:read)
        end

        describe 'with nil' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: :file)
          end

          it 'should raise an exception' do
            expect { subject.read_file(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) do
            'file is not a String or IO stream'
          end

          it 'should raise an exception' do
            expect { subject.read_file(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty String' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: :file)
          end

          it 'should raise an exception' do
            expect { subject.read_file('') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an IO stream' do
          let(:stream) { StringIO.new('Greetings, programs!') }

          it { expect(subject.read_file(stream)).to be == stream.string }
        end

        describe 'with an invalid absolute path' do
          let(:path) { invalid_absolute_path }
          let(:error_class) do
            Cuprum::Cli::Dependencies::FileSystem::FileNotFoundError
          end
          let(:error_message) do
            "unable to read file #{path} - file not found"
          end

          it 'should raise an exception' do
            expect { subject.read_file(path) }
              .to raise_error(error_class, error_message)
          end
        end

        describe 'with an invalid qualified path' do
          let(:path) { invalid_qualified_path }
          let(:error_class) do
            Cuprum::Cli::Dependencies::FileSystem::FileNotFoundError
          end
          let(:error_message) do
            "unable to read file #{path} - file not found"
          end

          it 'should raise an exception' do
            expect { subject.read_file(path) }
              .to raise_error(error_class, error_message)
          end
        end

        describe 'with an invalid relative path' do
          let(:path) { invalid_relative_path }
          let(:error_class) do
            Cuprum::Cli::Dependencies::FileSystem::FileNotFoundError
          end
          let(:error_message) do
            "unable to read file #{path} - file not found"
          end

          it 'should raise an exception' do
            expect { subject.read_file(path) }
              .to raise_error(error_class, error_message)
          end
        end

        wrap_deferred 'with valid file paths' do
          describe 'with an absolute path to a directory' do
            let(:path) { absolute_directory_path }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::FileIsADirectoryError
            end
            let(:error_message) do
              "unable to read file #{path} - file is a directory"
            end

            it 'should raise an exception' do
              expect { subject.read_file(path) }
                .to raise_error(error_class, error_message)
            end
          end

          describe 'with an absolute path to a file' do
            let(:path) { absolute_file_path }

            it { expect(subject.read_file(path)).to be == expected_contents }
          end

          describe 'with a qualified path to a directory' do
            let(:path) { qualified_directory_path }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::FileIsADirectoryError
            end
            let(:error_message) do
              "unable to read file #{path} - file is a directory"
            end

            it 'should raise an exception' do
              expect { subject.read_file(path) }
                .to raise_error(error_class, error_message)
            end
          end

          describe 'with a qualified path to a file' do
            let(:path) { qualified_file_path }

            it { expect(subject.read_file(path)).to be == expected_contents }
          end

          describe 'with a relative path to a directory' do
            let(:path) { relative_directory_path }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::FileIsADirectoryError
            end
            let(:error_message) do
              "unable to read file #{path} - file is a directory"
            end

            it 'should raise an exception' do
              expect { subject.read_file(path) }
                .to raise_error(error_class, error_message)
            end
          end

          describe 'with a relative path to a file' do
            let(:path) { relative_file_path }

            it { expect(subject.read_file(path)).to be == expected_contents }
          end

          wrap_deferred 'with valid file paths' do
            describe 'with a qualified path to a directory' do
              let(:path) { qualified_directory_path }
              let(:error_class) do
                Cuprum::Cli::Dependencies::FileSystem::FileIsADirectoryError
              end
              let(:error_message) do
                "unable to read file #{path} - file is a directory"
              end

              it 'should raise an exception' do
                expect { subject.read_file(path) }
                  .to raise_error(error_class, error_message)
              end
            end

            describe 'with a qualified path to a file' do
              let(:path) { qualified_file_path }

              it { expect(subject.read_file(path)).to be == expected_contents }
            end

            describe 'with a relative path to a directory' do
              let(:path) { relative_directory_path }
              let(:error_class) do
                Cuprum::Cli::Dependencies::FileSystem::FileIsADirectoryError
              end
              let(:error_message) do
                "unable to read file #{path} - file is a directory"
              end

              it 'should raise an exception' do
                expect { subject.read_file(path) }
                  .to raise_error(error_class, error_message)
              end
            end

            describe 'with a relative path to a file' do
              let(:path) { relative_file_path }

              it { expect(subject.read_file(path)).to be == expected_contents }
            end
          end
        end
      end

      describe '#root_path' do
        include_examples 'should define reader', :root_path, Dir.pwd

        wrap_deferred 'when initialized with root_path: value' do
          it { expect(subject.root_path).to be == root_path }
        end
      end

      describe '#with_tempfile' do
        let(:expected_tempfile) do
          respond_to(:read)
            .and(respond_to(:write)
            .and(respond_to(:path)))
        end

        it 'should define the method' do
          expect(subject)
            .to respond_to(:with_tempfile)
            .with(0).arguments
            .and_a_block
        end

        it 'should yield the file object' do
          expect { |block| subject.with_tempfile(&block) }
            .to yield_with_args(expected_tempfile)
        end
      end

      describe '#write_file', writeable_root_path: true do
        let(:invalid_absolute_path) do
          defined?(super()) ? super() : '/invalid-absolute-path'
        end
        let(:invalid_qualified_path) do
          defined?(super()) ? super() : '../invalid-qualified-path'
        end
        let(:invalid_relative_path) do
          defined?(super()) ? super() : 'invalid-relative-path'
        end
        let(:file_name) { "#{SecureRandom.uuid}.txt" }
        let(:data)      { "Greetings, programs!\n" }

        include_deferred 'with valid file paths'

        it { expect(subject).to respond_to(:write_file).with(2).arguments }

        it 'should define the aliased method' do
          expect(subject).to have_aliased_method(:write_file).as(:write)
        end

        describe 'with data: nil' do
          let(:data)   { nil }
          let(:stream) { StringIO.new }

          it 'should not write to the stream' do
            expect { subject.write_file(stream, data) }
              .not_to change(stream, :string)
          end
        end

        describe 'with data: an Object' do
          let(:data)   { Object.new.freeze }
          let(:stream) { StringIO.new }

          it 'should write the object to the stream' do
            expect { subject.write_file(stream, data) }
              .to change(stream, :string)
              .to be == data.inspect
          end
        end

        describe 'with data: an empty String' do
          let(:data)   { '' }
          let(:stream) { StringIO.new }

          it 'should not write to the stream' do
            expect { subject.write_file(stream, data) }
              .not_to change(stream, :string)
          end
        end

        describe 'with file: nil' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: :file)
          end

          it 'should raise an exception' do
            expect { subject.write_file(nil, data) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with file: an Object' do
          let(:error_message) do
            'file is not a String or IO stream'
          end

          it 'should raise an exception' do
            expect { subject.write_file(Object.new.freeze, data) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with file: an empty String' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: :file)
          end

          it 'should raise an exception' do
            expect { subject.write_file('', data) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with file: an IO stream' do
          let(:stream) { StringIO.new }

          it 'should write the data to the stream' do
            expect { subject.write_file(stream, data) }
              .to change(stream, :string)
              .to be == data
          end
        end

        describe 'with an absolute path' do
          let(:directory) do
            File.join(subject.root_path, writeable_path)
          end
          let(:path) do
            File.join(directory, "#{SecureRandom.uuid}.txt")
          end

          include_deferred 'when created files are cleaned up'

          it 'should write the data to a new file' do
            subject.write_file(path, data)

            expect(subject.read_file(path)).to be == data
          end

          context 'when the directory is not writeable' do
            let(:directory) { invalid_absolute_path }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryNotFoundError
            end
            let(:error_message) do
              "unable to write file #{path} - directory not found"
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end

          context 'when the file already exists' do
            before(:example) do
              subject.write_file(path, "Existing contents...\n")
            end

            it 'should replace the contents of the file' do
              subject.write_file(path, data)

              expect(subject.read_file(path)).to be == data
            end
          end

          context 'when the file is a directory' do
            let(:path) { directory }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::FileIsADirectoryError
            end
            let(:error_message) do
              "unable to write file #{path} - file is a directory"
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end

          context 'when the path includes a file' do
            let(:directory) { File.join(super(), 'a_file') }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryIsAFileError
            end
            let(:error_message) do
              "unable to write file #{path} - directory is a file"
            end

            before(:example) do
              subject.write_file(directory, "Existing contents...\n")
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end

          context 'when the path includes missing directories' do
            let(:directory) do
              File.join(super(), 'missing', 'directories')
            end
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryNotFoundError
            end
            let(:error_message) do
              "unable to write file #{path} - directory not found"
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end
        end

        describe 'with a qualified path' do
          let(:directory) do
            File.join('.', writeable_path)
          end
          let(:path) do
            File.join(directory, "#{SecureRandom.uuid}.txt")
          end

          include_deferred 'when created files are cleaned up'

          it 'should write the data to a new file' do
            subject.write_file(path, data)

            expect(subject.read_file(path)).to be == data
          end

          context 'when the directory is not writeable' do
            let(:directory) { invalid_absolute_path }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryNotFoundError
            end
            let(:error_message) do
              "unable to write file #{path} - directory not found"
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end

          context 'when the file already exists' do
            before(:example) do
              subject.write_file(path, "Existing contents...\n")
            end

            it 'should replace the contents of the file' do
              subject.write_file(path, data)

              expect(subject.read_file(path)).to be == data
            end
          end

          context 'when the file is a directory' do
            let(:path) { directory }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::FileIsADirectoryError
            end
            let(:error_message) do
              "unable to write file #{path} - file is a directory"
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end

          context 'when the path includes a file' do
            let(:directory) { File.join(super(), 'a_file') }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryIsAFileError
            end
            let(:error_message) do
              "unable to write file #{path} - directory is a file"
            end

            before(:example) do
              subject.write_file(directory, "Existing contents...\n")
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end

          context 'when the path includes missing directories' do
            let(:directory) do
              File.join(super(), 'missing', 'directories')
            end
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryNotFoundError
            end
            let(:error_message) do
              "unable to write file #{path} - directory not found"
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end
        end

        describe 'with a relative path' do
          let(:directory) do
            writeable_path
          end
          let(:path) do
            File.join(directory, "#{SecureRandom.uuid}.txt")
          end

          include_deferred 'when created files are cleaned up'

          it 'should write the data to a new file' do
            subject.write_file(path, data)

            expect(subject.read_file(path)).to be == data
          end

          context 'when the directory is not writeable' do
            let(:directory) { invalid_absolute_path }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryNotFoundError
            end
            let(:error_message) do
              "unable to write file #{path} - directory not found"
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end

          context 'when the file already exists' do
            before(:example) do
              subject.write_file(path, "Existing contents...\n")
            end

            it 'should replace the contents of the file' do
              subject.write_file(path, data)

              expect(subject.read_file(path)).to be == data
            end
          end

          context 'when the file is a directory' do
            let(:path) { directory }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::FileIsADirectoryError
            end
            let(:error_message) do
              "unable to write file #{path} - file is a directory"
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end

          context 'when the path includes a file' do
            let(:directory) { File.join(super(), 'a_file') }
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryIsAFileError
            end
            let(:error_message) do
              "unable to write file #{path} - directory is a file"
            end

            before(:example) do
              subject.write_file(directory, "Existing contents...\n")
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end

          context 'when the path includes missing directories' do
            let(:directory) do
              File.join(super(), 'missing', 'directories')
            end
            let(:error_class) do
              Cuprum::Cli::Dependencies::FileSystem::DirectoryNotFoundError
            end
            let(:error_message) do
              "unable to write file #{path} - directory not found"
            end

            it 'should raise an exception' do
              expect { subject.write_file(path, data) }
                .to raise_error(error_class, error_message)
            end
          end
        end

        wrap_deferred 'when initialized with root_path: value' do
          include_deferred 'when created files are cleaned up'

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
              subject.write_file(path, data)

              expect(subject.read_file(path)).to be == data
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
              subject.write_file(path, data)

              expect(subject.read_file(path)).to be == data
            end
          end
        end
      end
    end
  end
end
