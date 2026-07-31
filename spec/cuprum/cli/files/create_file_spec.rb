# frozen_string_literal: true

require 'cuprum/cli/dependencies/file_system/mock'
require 'cuprum/cli/dependencies/standard_io/mock'
require 'cuprum/cli/files/create_file'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Files::CreateFile do
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:command) do
    described_class.new(file_system:, standard_io:, **options)
  end

  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new }
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }
  let(:options)     { {} }

  include_deferred 'should define option',
    :directories,
    type:    :boolean,
    default: true

  include_deferred 'should define option',
    :dry_run,
    type:    :boolean,
    default: false

  include_deferred 'should define option',
    :force,
    type:    :boolean,
    default: false

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end

    describe 'with invalid options' do
      let(:options) { super().merge(invalid_option: 'invalid value') }
      let(:error_message) do
        "unrecognized option :invalid_option for #{described_class.name} " \
          '- valid options are :directories, :dry_run, :force'
      end

      it 'should raise an exception' do
        expect { described_class.new(**options) }.to raise_error(
          Cuprum::Cli::Options::UnknownOptionError,
          error_message
        )
      end
    end
  end

  describe '#call' do
    deferred_examples 'should generate the file' do
      it 'should return a passing result' do
        expect(call_command)
          .to be_a_passing_result
          .with_value(file_path)
      end

      it 'should write the file to the file system' do
        call_command

        expect(file_system.read(file_path)).to be == contents
      end

      describe 'when initialized with dry_run: true' do
        let(:options) { super().merge(dry_run: true) }

        it 'should return a passing result' do
          expect(call_command)
            .to be_a_passing_result
            .with_value(file_path)
        end

        it 'should not write the file to the file system' do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
          if file_system.file?(file_path)
            expect { call_command }
              .not_to(change { file_system.read_file(file_path) })
          else
            expect { call_command }
              .not_to(change { file_system.file?(file_path) })
          end
        end
      end
    end

    let(:file_path) { 'file.rb' }
    let(:contents) do
      <<~MARKDOWN
        # Greetings, Starfighter

        You have been recruited by the Star League to defend the frontier
        against Xur and the Ko-Dan armada!
      MARKDOWN
    end

    define_method(:call_command) do
      command.call(contents:, file_path:)
    end

    it 'should define the method' do
      expect(command)
        .to be_callable
        .with(0).arguments
        .and_keywords(:contents, :file_path)
    end

    include_deferred 'should generate the file'

    context 'when the file path is not writeable' do
      let(:file_path) { 'templates' }
      let(:expected_error) do
        Cuprum::Cli::Errors::Files::FileNotWriteable.new(
          file_path:,
          reason:    'file is a directory'
        )
      end

      before(:example) { file_system.create_directory(file_path) }

      it 'should return a failing result' do
        expect(call_command)
          .to be_a_failing_result
          .with_error(expected_error)
      end

      it 'should not write the file to the file system' do
        expect { call_command }
          .not_to(change { file_system.file?(file_path) })
      end
    end

    context 'when the file path already exists' do
      let(:expected_error) do
        Cuprum::Cli::Errors::Files::FileNotWriteable.new(
          file_path:,
          reason:    'file already exists'
        )
      end

      before(:example) do
        file_system.write_file(file_path, "Existing contents...\n")
      end

      it 'should return a failing result' do
        expect(call_command)
          .to be_a_failing_result
          .with_error(expected_error)
      end

      it 'should not write the file to the file system' do
        expect { call_command }
          .not_to(change { file_system.read_file(file_path) })
      end

      context 'when initialized with force: true' do
        let(:options) { super().merge(force: true) }

        include_deferred 'should generate the file'
      end
    end

    context 'when the file path requires intermediate directories' do
      let(:file_path) { 'files/path/to/file.rb' }

      include_deferred 'should generate the file'

      context 'when initialized with directories: false' do
        let(:options) { super().merge(directories: false) }
        let(:expected_error) do
          Cuprum::Cli::Errors::Files::FileNotWriteable.new(
            file_path:,
            reason:    'directory not found'
          )
        end

        it 'should return a failing result' do
          expect(call_command)
            .to be_a_failing_result
            .with_error(expected_error)
        end

        it 'should not write the file to the file system' do
          expect { call_command }
            .not_to(change { file_system.file?(file_path) })
        end
      end
    end
  end
end
