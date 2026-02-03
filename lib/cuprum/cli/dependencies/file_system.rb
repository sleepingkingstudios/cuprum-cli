# frozen_string_literal: true

require 'stringio'
require 'tempfile'

require 'cuprum/cli/dependencies'

module Cuprum::Cli::Dependencies
  # Utility wrapping filesystem operations.
  class FileSystem
    # @param root_path [String] the path to the root directory. Defaults to the
    #   value of __dir__.
    def initialize(root_path: Dir.pwd)
      @root_path = root_path
    end

    # @return [String] the path to the root directory.
    attr_reader :root_path

    # Checks if the requested directory exists.
    #
    # @param path [String] the path to the requested directory.
    #
    # @return [true, false] true if the directory exists and is a directory,
    #   otherwise false.
    def directory?(path)
      tools.assertions.validate_name(path, as: 'path')

      path = resolve_path(path)

      File.exist?(path) && File.directory?(path)
    end
    alias directory_exists? directory?

    # @overload each_file
    #   Iterates over file names matching the given pattern.
    #
    #   @param pattern [String] the file pattern to match.
    #
    #   @return [Enumerator<String>] an enumerator over the matching file names.
    #
    # @overload each_file { |file| }
    #   Yields each file name matching the given pattern.
    #
    #   @param pattern [String] the file pattern to match.
    #
    #   @return [Array<String>] the matching file names.
    #
    #   @yieldparam [String] the matching file name.
    def each_file(pattern, &)
      return enum_for(:each_file, pattern) unless block_given?

      path = resolve_path(pattern)

      Dir[path].each(&)
    end

    # Checks if the requested file exists.
    #
    # @param path [String] the path to the requested file.
    #
    # @return [true, false] true if the file exists and is a file,
    #   otherwise false.
    def file?(path)
      tools.assertions.validate_name(path, as: 'path')

      path = resolve_path(path)

      File.exist?(path) && File.file?(path)
    end
    alias file_exists? file?

    # @overload read_file(file)
    #   Reads the contents of the given file or IO stream.
    #
    #   @param file [IO] the file to read.
    #
    #   @return [String] the file contents.
    #
    # @overload read_file(path)
    #   Reads the contents of the file at the given path.
    #
    #   @param path [String] the file path to read.
    #
    #   @return [String] the file contents.
    def read_file(file_or_path)
      validate_file(file_or_path, as: 'file')

      return file_or_path.read if io_stream?(file_or_path)

      path = resolve_path(file_or_path)

      File.read(path)
    end
    alias read read_file

    # Creates a tempfile and passes it to the block.
    #
    # @yieldparam [File] the generated tempfile.
    #
    # @return [Object] the value returned by the block.
    def with_tempfile(&) = Tempfile.create(&)

    # @overload write_file(file, data)
    #   Writes the data to the given file or IO stream.
    #
    #   @param file [IO] the file to write.
    #   @param data [String] the data to write.
    #
    #   @return [Integer] the number of bytes written.
    #
    # @overload write_file(path, data)
    #   Writes the data to the file at the given path.
    #
    #   @param path [String] the file path to write.
    #   @param data [String] the data to write.
    #
    #   @return [Integer] the number of bytes written.
    def write_file(file_or_path, data)
      validate_file(file_or_path, as: 'file')

      return file_or_path.write(data) if io_stream?(file_or_path)

      path = resolve_path(file_or_path)

      File.write(path, data)
    end
    alias write write_file

    private

    def empty_file_message(as:)
      tools.assertions.error_message_for('presence', as:)
    end

    def invalid_file_message(as:)
      "#{as} is not a String or IO stream"
    end

    def io_stream?(file_or_path)
      file_or_path.is_a?(IO) || file_or_path.is_a?(StringIO)
    end

    def resolve_path(path)
      return path if File.absolute_path?(path)

      File.expand_path(File.join(root_path, path))
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    def validate_file(file_or_path, as:)
      case file_or_path
      in IO | StringIO
        nil
      in nil | ''
        raise ArgumentError, empty_file_message(as:)
      in String # rubocop:disable Lint/DuplicateBranch
        nil
      else
        raise ArgumentError, invalid_file_message(as:)
      end
    end
  end
end
