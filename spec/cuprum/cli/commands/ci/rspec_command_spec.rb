# frozen_string_literal: true

require 'cuprum/cli/commands/ci/rspec_command'
require 'cuprum/cli/rspec/deferred/arguments_examples'
require 'cuprum/cli/rspec/deferred/ci/report_examples'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Commands::Ci::RSpecCommand do # rubocop:disable RSpec/SpecFilePathFormat
  include Cuprum::Cli::RSpec::Deferred::ArgumentsExamples
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:command) do
    described_class.new(file_system:, standard_io:, system_command:)
  end

  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new }
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }
  let(:system_command) do
    Cuprum::Cli::Dependencies::SystemCommand::Mock.new(captures:)
  end
  let(:captures) do
    { 'rspec' => rspec_mock }
  end
  let(:rspec_mock) do
    lambda do |arguments:, **|
      argument = arguments.find { |str| str.start_with?('--out') }
      tempfile = argument.split('=').last

      file_system.write_file(tempfile, json)

      ['', '', 0]
    end
  end

  describe '::Report' do
    include Cuprum::Cli::RSpec::Deferred::Ci::ReportExamples

    subject(:report) { described_class.new(**properties) }

    let(:described_class) { super()::Report }
    let(:properties)      { { duration: 1.0, total_count: 100 } }

    include_deferred 'should implement the CI report interface',
      item_name: 'example'
  end

  include_deferred 'should define argument', 0, :file_patterns, variadic: true

  include_deferred 'should define option',
    :color,
    type:    :boolean,
    default: true
  include_deferred 'should define option',
    :coverage,
    type:    :boolean,
    default: false
  include_deferred 'should define option',
    :env,
    type:    :hash,
    default: {}
  include_deferred 'should define option',
    :format,
    type:    :string,
    default: 'progress'
  include_deferred 'should define option',
    :gemfile,
    type:    :string,
    default: nil

  include_deferred 'should define --quiet option'

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe '#call' do
    deferred_examples 'should run the rspec command' do
      it 'should run the rspec command', :aggregate_failures do
        expect { command.call(*arguments, **options) }.to(
          change { system_command.recorded_commands.count }.by(1)
        )

        expect(last_run_command)
          .to be == expected_command
      end
    end

    let(:arguments) { [] }
    let(:options)   { {} }
    let(:json) do
      <<~JSON
        {
          "summary": {
            "duration": 0.5,
            "example_count": 10,
            "failure_count": 1,
            "pending_count": 2,
            "errors_outside_of_examples_count": 0
          }
        }
      JSON
    end
    let(:expected_value) do
      described_class::Report.new(
        label:         'ci:rspec',
        duration:      0.5,
        error_count:   0,
        failure_count: 1,
        pending_count: 2,
        total_count:   10
      )
    end
    let(:tempfile_pattern) do
      /\h{8}-\h{4}-\h{4}-\h{4}-\h{12}/
    end
    let(:expected_command) do
      tempfile = File.join(file_system.root_path, 'tempfiles', 'a_uuid')

      'COVERAGE=false rspec ' \
        '--force-color ' \
        "--format=json --out=#{tempfile} " \
        '--format="progress"'
    end
    let(:last_run_command) do
      system_command.recorded_commands.last.sub(tempfile_pattern, 'a_uuid')
    end

    it { expect(command).to be_callable }

    it 'should return a passing result' do
      expect(command.call)
        .to be_a_passing_result
        .with_value(expected_value)
    end

    include_deferred 'should run the rspec command'

    context 'when the process does not write JSON to the tempfile' do
      let(:json) { '' }
      let(:error_message) do
        JSON.parse(json)
      rescue JSON::ParserError => exception
        exception.message
      end
      let(:expected_error) do
        message = "unable to parse JSON results - #{error_message}"

        Cuprum::Error.new(message:)
      end

      it 'should return a failing result' do
        expect(command.call)
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    context 'when the process writes invalid JSON to the tempfile' do
      let(:json) { 'not JSON, sorry' }
      let(:error_message) do
        JSON.parse(json)
      rescue JSON::ParserError => exception
        exception.message
      end
      let(:expected_error) do
        message = "unable to parse JSON results - #{error_message}"

        Cuprum::Error.new(message:)
      end

      it 'should return a failing result' do
        expect(command.call)
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with file patterns' do
      let(:arguments) do
        %w[
          spec/path/to/file
          spec/path/to/dir/*_spec.rb
        ]
      end
      let(:expected_command) do
        tempfile = File.join(file_system.root_path, 'tempfiles', 'a_uuid')

        'COVERAGE=false rspec spec/path/to/file spec/path/to/dir/*_spec.rb ' \
          '--force-color ' \
          "--format=json --out=#{tempfile} " \
          '--format="progress"'
      end

      include_deferred 'should run the rspec command'
    end

    describe 'with color: false' do
      let(:options) { super().merge(color: false) }
      let(:expected_command) do
        tempfile = File.join(file_system.root_path, 'tempfiles', 'a_uuid')

        'COVERAGE=false rspec ' \
          '--no-color ' \
          "--format=json --out=#{tempfile} " \
          '--format="progress"'
      end

      include_deferred 'should run the rspec command'
    end

    describe 'with coverage: true' do
      let(:options) { super().merge(coverage: true) }
      let(:expected_command) do
        tempfile = File.join(file_system.root_path, 'tempfiles', 'a_uuid')

        'rspec ' \
          '--force-color ' \
          "--format=json --out=#{tempfile} " \
          '--format="progress"'
      end

      include_deferred 'should run the rspec command'
    end

    describe 'with env: value' do
      let(:options) { super().merge(env: { custom_env: 'value' }) }
      let(:expected_command) do
        tempfile = File.join(file_system.root_path, 'tempfiles', 'a_uuid')

        'CUSTOM_ENV="value" COVERAGE=false rspec ' \
          '--force-color ' \
          "--format=json --out=#{tempfile} " \
          '--format="progress"'
      end

      include_deferred 'should run the rspec command'
    end

    describe 'with format: value' do
      let(:options) { super().merge(format: 'doc') }
      let(:expected_command) do
        tempfile = File.join(file_system.root_path, 'tempfiles', 'a_uuid')

        'COVERAGE=false rspec ' \
          '--force-color ' \
          "--format=json --out=#{tempfile} " \
          '--format="doc"'
      end

      include_deferred 'should run the rspec command'
    end

    describe 'with gemfile: value' do
      let(:options) { super().merge(gemfile: 'gemfiles/custom.gemfile') }
      let(:expected_command) do
        tempfile = File.join(file_system.root_path, 'tempfiles', 'a_uuid')

        'COVERAGE=false BUNDLER_GEMFILE="gemfiles/custom.gemfile" rspec ' \
          '--force-color ' \
          "--format=json --out=#{tempfile} " \
          '--format="progress"'
      end

      include_deferred 'should run the rspec command'
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
