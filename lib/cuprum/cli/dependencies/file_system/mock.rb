# frozen_string_literal: true

require 'cuprum/cli/dependencies/file_system'

module Cuprum::Cli::Dependencies
  # Mock implementation of FileSystem for testing purposes.
  class FileSystem::Mock < Cuprum::Cli::Dependencies::FileSystem # rubocop:disable Metrics/ClassLength
    SINGLE_GLOB_PATTERN = /\*+/
    private_constant :SINGLE_GLOB_PATTERN

    # Exception raised when trying to read from or write to a non-mocked path.
    class InvalidPathError < StandardError; end

    # Utility class used to simulate tempfile behavior.
    class MockTempfile < SimpleDelegator
      # @param path [String] the qualified path to the tempfile.
      def initialize(path)
        super(StringIO.new)

        @path = path
      end

      # @return [String] the qualified path to the tempfile.
      attr_reader :path
    end

    # @param files [Hash{String => Hash, IO}] the mocked directories and files.
    #   Must be a Hash with String keys representing file path segments; Hash
    #   values represent directories, while IO values represent files.
    # @param root_path [String] the path to the root directory. Defaults to the
    #   value of `Dir.pwd`.
    def initialize(files: {}, root_path: Dir.pwd)
      super(root_path:)

      @files     = files
      @tempfiles = []
    end

    # @return [Hash{String => Hash, IO}] the mocked directories and files.
    attr_reader :files

    # @return [Array<String>] the contents of each generated tempfile.
    attr_reader :tempfiles

    # (see Cuprum::Cli::Dependencies::FileSystem#create_directory)
    def create_directory(path, recursive: false) # rubocop:disable Metrics/MethodLength
      tools.assertions.validate_name(path, as: 'path')

      *dir_names, dir_name = split_path(resolve_path(path))

      directory = write_directory(
        *dir_names,
        action:       'create directory',
        file_or_path: path,
        recursive:
      )

      if io_stream?(directory[dir_name])
        raise DirectoryIsAFileError,
          "unable to create directory #{path} - directory is a file"
      end

      directory[dir_name] = {}

      path
    end
    alias make_directory create_directory

    # (see Cuprum::Cli::Dependencies::FileSystem#directory?)
    def directory?(path)
      tools.assertions.validate_name(path, as: 'path')

      path = resolve_path(path)
      mock = resolve_mock(path)

      mock.is_a?(Hash)
    end
    alias directory_exists? directory?

    # (see Cuprum::Cli::Dependencies::FileSystem#each_file)
    def each_file(pattern, &)
      return enum_for(:each_file, pattern) unless block_given?

      flattened_files.each do |file_path|
        next unless matches_pattern?(file_path:, pattern:)

        yield File.join(root_path, file_path)
      end

      nil
    end

    # (see Cuprum::Cli::Dependencies::FileSystem#directory?)
    def file?(path)
      tools.assertions.validate_name(path, as: 'path')

      path = resolve_path(path)
      mock = resolve_mock(path)

      io_stream?(mock)
    end
    alias file_exists? file?

    # (see Cuprum::Cli::Dependencies::FileSystem#read_file)
    def read_file(file_or_path) # rubocop:disable Metrics/MethodLength
      validate_file(file_or_path, as: 'file')

      return file_or_path.read if io_stream?(file_or_path)

      path = resolve_path(file_or_path)

      unless path.start_with?(root_path)
        raise FileNotFoundError,
          "unable to read file #{file_or_path} - file not found"
      end

      mock = resolve_mock(path)

      return mock.tap(&:rewind).read if io_stream?(mock)

      if mock
        raise FileIsADirectoryError,
          "unable to read file #{file_or_path} - file is a directory"
      end

      raise FileNotFoundError,
        "unable to read file #{file_or_path} - file not found"
    end
    alias read read_file

    # (see Cuprum::Cli::Dependencies::FileSystem#with_tempfile)
    def with_tempfile(&block)
      file_name = SecureRandom.uuid
      file_path = File.join(root_path, 'tempfiles', file_name)

      tempfile = MockTempfile.new(file_path)

      (files['tempfiles'] ||= {})[file_name] = tempfile

      block.call(tempfile).tap do
        tempfiles << read_file(tempfile.tap(&:rewind))
      end
    ensure
      files['tempfiles'].delete(file_name)
    end

    # (see Cuprum::Cli::Dependencies::FileSystem#write_file)
    def write_file(file_or_path, data) # rubocop:disable Metrics/MethodLength
      validate_file(file_or_path, as: 'file')

      return file_or_path.write(data) if io_stream?(file_or_path)

      path = resolve_path(file_or_path)

      unless path.start_with?(root_path)
        raise DirectoryNotFoundError,
          "unable to write file #{file_or_path} - directory not found"
      end

      mock = resolve_mock(path)

      if mock.is_a?(MockTempfile)
        mock.write(data)
        mock.rewind

        return
      end

      if mock.nil? || io_stream?(mock)
        return write_mock_file(path, data, file_or_path)
      end

      raise FileIsADirectoryError,
        "unable to write file #{file_or_path} - file is a directory"
    end
    alias write write_file

    private

    def flatten_files(files:, flat: [], path: '')
      files.each do |name, value|
        qualified_path = path.empty? ? name : File.join(path, name)

        next flat << qualified_path unless value.is_a?(Hash)

        flatten_files(files: value, flat:, path: qualified_path)
      end

      flat
    end

    def flattened_files
      @flattened_files || flatten_files(files:)
    end

    def io_stream?(file_or_path)
      super || file_or_path.is_a?(MockTempfile)
    end

    def matches_globbed_pattern?(entry_names:, pattern_strings:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      prefix_index   = pattern_strings.index { |str| str.include?('**') }
      prefix_strings = pattern_strings[...prefix_index]
      prefix_count   = prefix_strings.length
      suffix_index   = pattern_strings.rindex { |str| str.include?('**') }
      suffix_strings = pattern_strings[(1 + suffix_index)..]
      suffix_count   = suffix_strings.length

      return false unless entry_names.length >= prefix_count + suffix_count

      entry_names[...prefix_count]
        .zip(prefix_strings)
        .concat(entry_names[-suffix_count...].zip(suffix_strings))
        .all? do |entry_name, pattern_string|
          matches_pattern_string?(entry_name:, pattern_string:)
        end
    end

    def matches_pattern?(file_path:, pattern:)
      entry_names     = file_path.split(File::SEPARATOR)
      pattern_strings = pattern.split(File::SEPARATOR)

      if pattern_strings.any? { |str| str.include?('**') }
        return matches_globbed_pattern?(entry_names:, pattern_strings:)
      end

      return false unless entry_names.length == pattern_strings.length

      entry_names.zip(pattern_strings).all? do |entry_name, pattern_string|
        matches_pattern_string?(entry_name:, pattern_string:)
      end
    end

    def matches_pattern_string?(entry_name:, pattern_string:)
      if pattern_string.include?('*')
        pattern_string
          .gsub('.', '\.')
          .gsub(SINGLE_GLOB_PATTERN, '.*')
          .then { |str| Regexp.new(str) }
          .match?(entry_name)
      else
        entry_name == pattern_string
      end
    end

    def resolve_mock(path)
      return unless path.start_with?(root_path)

      *rest, last = split_path(path)

      dir = rest.reduce(files) do |dir, segment|
        break if dir[segment].nil? || io_stream?(dir[segment])

        dir[segment]
      end

      dir&.[](last)
    end

    def split_path(path)
      path[(1 + root_path.length)..]
        &.split(File::SEPARATOR) || []
    end

    def write_directory(*dir_names, action:, file_or_path:, recursive: false)
      dir_names.reduce(files) do |dir, dir_name|
        if io_stream?(dir[dir_name])
          raise DirectoryIsAFileError,
            "unable to #{action} #{file_or_path} - directory is a file"
        elsif dir[dir_name].nil? && !recursive
          raise DirectoryNotFoundError,
            "unable to #{action} #{file_or_path} - directory not found"
        end

        dir[dir_name] ||= {}
      end
    end

    def write_mock_file(path, data, file_or_path)
      *dir_names, file_name = split_path(path)

      directory = write_directory(
        *dir_names,
        action:       'write file',
        file_or_path:,
        recursive:    false
      )

      directory[file_name] = StringIO.new(data.to_s)
    end

    def validate_file(file_or_path, as:)
      return if file_or_path.is_a?(MockTempfile)

      super
    end
  end
end
