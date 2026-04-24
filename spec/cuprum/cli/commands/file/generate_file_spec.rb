# frozen_string_literal: true

require 'cuprum/cli/commands/file/generate_file'
require 'cuprum/cli/dependencies/file_system/mock'
require 'cuprum/cli/dependencies/standard_io/mock'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Commands::File::GenerateFile do
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:command) do
    described_class.new(file_system:, standard_io:, **options)
  end

  deferred_context 'when the template file exists' do
    let(:template) { defined?(super()) ? super() : "Greetings, starfighter!\n" }

    before(:example) { file_system.write_file(template_path, template) }
  end

  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new(files:) }
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }
  let(:options)     { {} }
  let(:files) do
    { 'templates' => {} }
  end

  include_deferred 'should define option',
    :dry_run,
    type:    :boolean,
    default: false

  include_deferred 'should define option',
    :force,
    type:    :boolean,
    default: false

  include_deferred 'should define --quiet option'

  include_deferred 'should define --verbose option'

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
          '- valid options are :directories, :dry_run, :force, :quiet, :verbose'
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

      it 'should output the results' do
        call_command

        expect(standard_io.combined_stream.tap(&:rewind).read)
          .to be == expected_output
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

        it 'should output the results' do
          call_command

          expect(standard_io.combined_stream.tap(&:rewind).read)
            .to be == expected_output
        end
      end

      describe 'when initialized with quiet: true' do
        let(:options) { super().merge(quiet: true) }

        it 'should not output the results' do
          call_command

          expect(standard_io.combined_stream.tap(&:rewind).read).to be == ''
        end
      end

      describe 'when initialized with verbose: true' do
        let(:options) { super().merge(verbose: true) }
        let(:expected_output) do
          <<~OUTPUT
            Generating file #{file_path}...

            #{
              contents
                .each_line
                .map { |line| line == "\n" ? "\n" : "  #{line}" }
                .join
            }
          OUTPUT
        end

        it 'should output the results' do
          call_command

          expect(standard_io.combined_stream.tap(&:rewind).read)
            .to be == expected_output
        end
      end
    end

    let(:file_path)     { 'file.rb' }
    let(:template_path) { 'templates/template.rb' }
    let(:parameters)    { {} }
    let(:contents)      { template }
    let(:expected_output) do
      "Generating file #{file_path}...\n"
    end

    define_method(:call_command) do
      command.call(file_path:, parameters:, template_path:)
    end

    it 'should define the method' do
      expect(command)
        .to be_callable
        .with(0).arguments
        .and_keywords(:file_path, :parameters, :template_path)
    end

    context 'when the template file does not exist' do
      let(:expected_error) do
        Cuprum::Cli::Errors::Files::MissingTemplate.new(
          message:       "unable to generate file #{file_path}",
          template_path:
        )
      end

      it 'should return a failing result' do
        expect(call_command)
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    wrap_deferred 'when the template file exists' do
      include_deferred 'should generate the file'
    end

    context 'when the file path is not writeable' do
      let(:file_path) { './templates' }
      let(:expected_error) do
        Cuprum::Cli::Errors::Files::FileNotWriteable.new(
          file_path:,
          reason:    'file is a directory'
        )
      end

      include_deferred 'when the template file exists'

      it 'should return a failing result' do
        expect(call_command)
          .to be_a_failing_result
          .with_error(expected_error)
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

      include_deferred 'when the template file exists'

      it 'should return a failing result' do
        expect(call_command)
          .to be_a_failing_result
          .with_error(expected_error)
      end

      context 'when initialized with force: true' do
        let(:options) { super().merge(force: true) }

        include_deferred 'should generate the file'
      end
    end

    context 'when the file path requires intermediate directories' do
      let(:file_path) { 'files/path/to/file.rb' }

      include_deferred 'when the template file exists'

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
      end
    end

    context 'when the template has format: ERB' do
      let(:template_path) { 'templates/template.rb.erb' }
      let(:template) do
        <<~RUBY
          # frozen_string_literal: true

          puts 'Greetings, <%= greeting %>!'
        RUBY
      end

      include_deferred 'when the template file exists'

      describe 'with invalid parameters' do # rubocop:disable RSpec/MultipleMemoizedHelpers
        let(:expected_error) do
          Cuprum::Cli::Errors::Files::MissingParameter.new(
            message:        'unable to render ERB template',
            parameter_name: :greeting,
            template_name:  template_path
          )
        end

        it 'should return a failing result' do
          expect(call_command)
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'with valid parameters' do
        let(:parameters) { super().merge(greeting: 'starfighter') }
        let(:contents) do
          <<~RUBY
            # frozen_string_literal: true

            puts 'Greetings, starfighter!'
          RUBY
        end

        include_deferred 'should generate the file'
      end
    end
  end
end
