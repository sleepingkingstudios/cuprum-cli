# frozen_string_literal: true

require 'cuprum/cli/commands/ci/rspec_each_command'
require 'cuprum/cli/rspec/deferred/arguments_examples'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Commands::Ci::RSpecEachCommand do # rubocop:disable RSpec/SpecFilePathFormat
  include Cuprum::Cli::RSpec::Deferred::ArgumentsExamples
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:command) do
    described_class.new(file_system:, standard_io:)
  end

  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new }
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }

  include_deferred 'should define argument', 0, :file_patterns, variadic: true

  include_deferred 'should define option',
    :color,
    type:    :boolean,
    default: true
  include_deferred 'should define option',
    :env,
    type:    :hash,
    default: {}
  include_deferred 'should define option',
    :gemfile,
    type:    :string,
    default: nil

  include_deferred 'should define --quiet option'

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe '#call' do
    deferred_examples 'should call the RSpec command for each file' do
      let(:expected_options) do
        { env: command.env, gemfile: command.gemfile, quiet: true }
      end

      it 'should call the RSpec command for each file', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        command.call(*arguments, **options)

        expect(rspec_command)
          .to have_received(:call)
          .exactly(expected_files.count).times

        expected_files.each do |filename|
          expect(rspec_command)
            .to have_received(:call)
            .with(filename, **expected_options)
        end
      end

      describe 'with env: value' do
        let(:options) { super().merge(env: { custom_env: 'value' }) }

        it 'should call the RSpec command for each file', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
          command.call(*arguments, **options)

          expect(rspec_command)
            .to have_received(:call)
            .exactly(expected_files.count).times

          expected_files.each do |filename|
            expect(rspec_command)
              .to have_received(:call)
              .with(filename, **expected_options)
          end
        end
      end

      describe 'with gemfile: value' do
        let(:options) { super().merge(gemfile: 'gemfiles/custom.gemfile') }

        it 'should call the RSpec command for each file', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
          command.call(*arguments, **options)

          expect(rspec_command)
            .to have_received(:call)
            .exactly(expected_files.count).times

          expected_files.each do |filename|
            expect(rspec_command)
              .to have_received(:call)
              .with(filename, **expected_options)
          end
        end
      end
    end

    deferred_examples 'should output the results' do
      it 'should output the results' do
        command.call(*arguments, **options)

        expect(standard_io.combined_stream.string).to be == expected_output
      end

      describe 'with color: false' do
        let(:options) { super().merge(color: false) }
        let(:expected_output) do
          escape = "\e"

          super().gsub(/#{escape}\[\d+m/, '')
        end

        it 'should output the results' do
          command.call(*arguments, **options)

          expect(standard_io.combined_stream.string).to be == expected_output
        end
      end

      describe 'with quiet: true' do
        let(:options) { super().merge(quiet: true) }

        it 'should not output to stdout' do
          command.call(*arguments, **options)

          expect(standard_io.combined_stream.string).to be == ''
        end
      end
    end

    let(:arguments) { [] }
    let(:options)   { {} }
    let(:rspec_command) do
      instance_double(Cuprum::Cli::Commands::Ci::RSpecCommand, call: nil)
    end
    let(:rspec_report) do
      Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
        label:         'ci:rspec',
        duration:      0.0,
        error_count:   0,
        failure_count: 0,
        pending_count: 0,
        total_count:   0
      )
    end
    let(:rspec_results) do
      [
        Cuprum::Result.new(value: rspec_report)
      ]
    end

    before(:example) do
      allow(Cuprum::Cli::Commands::Ci::RSpecCommand)
        .to receive(:new)
        .and_return(rspec_command)

      allow(rspec_command).to receive(:call).and_return(*rspec_results)
    end

    it { expect(command).to be_callable }

    context 'when there are no matching spec files' do
      let(:expected_value) do
        Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
          label:         'ci:rspec_each',
          duration:      0.0,
          error_count:   0,
          failure_count: 0,
          pending_count: 0,
          total_count:   0
        )
      end
      let(:expected_output) do
        <<~RAW
          Running 0 spec files...

          Finished in 0.0 seconds
          \e[33m0 examples, 0 failures\e[0m
        RAW
      end

      it 'should return a passing result' do
        expect(command.call)
          .to be_a_passing_result
          .with_value(expected_value)
      end

      it 'should not call an RSpec command' do
        command.call

        expect(rspec_command).not_to have_received(:call)
      end

      include_deferred 'should output the results'
    end

    context 'when there are matching spec files' do
      let(:files) do
        {
          'root_dir'     => {
            'child_spec.rb'   => StringIO.new,
            'sibling_spec.rb' => StringIO.new
          },
          'root_spec.rb' => StringIO.new
        }
      end
      let(:file_system) do
        Cuprum::Cli::Dependencies::FileSystem::Mock.new(files:)
      end
      let(:reports) do
        Array.new(3) { {} }
      end
      let(:rspec_results) do
        reports.map do |properties|
          report = Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
            label:         'ci:rspec',
            duration:      2.0,
            error_count:   0,
            failure_count: 0,
            pending_count: 0,
            total_count:   10,
            **properties
          )

          Cuprum::Result.new(value: report)
        end
      end
      let(:expected_value) do
        Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
          label:         'ci:rspec_each',
          duration:      6.0,
          error_count:   0,
          failure_count: 0,
          pending_count: 0,
          total_count:   30
        )
      end
      let(:expected_files) do
        file_system.each_file('**/*').to_a
      end
      let(:expected_output) do
        <<~RAW
          Running 3 spec files...

          \e[32mPassing\e[0m root_dir/child_spec.rb
          \e[32mPassing\e[0m root_dir/sibling_spec.rb
          \e[32mPassing\e[0m root_spec.rb

          Finished in 6.0 seconds
          \e[32m30 examples, 0 failures\e[0m
        RAW
      end

      it 'should return a passing result' do
        expect(command.call(*arguments, **options))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      include_deferred 'should call the RSpec command for each file'

      include_deferred 'should output the results'

      context 'when a file returns a failing result' do
        let(:rspec_results) do
          results = super()

          [results[0], Cuprum::Result.new(status: :failure), results[2]]
        end
        let(:expected_value) do
          Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
            label:         'ci:rspec_each',
            duration:      4.0,
            error_count:   0,
            failure_count: 0,
            pending_count: 0,
            total_count:   20
          )
        end
        let(:expected_output) do
          <<~RAW
            Running 3 spec files...

            \e[32mPassing\e[0m root_dir/child_spec.rb
            \e[31mErrored\e[0m root_dir/sibling_spec.rb
            \e[32mPassing\e[0m root_spec.rb

            Errored:

            \e[31m  root_dir/sibling_spec.rb\e[0m

            Finished in 4.0 seconds
            \e[31m20 examples, 0 failures\e[0m
          RAW
        end

        it 'should return a passing result' do
          expect(command.call(*arguments, **options))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        include_deferred 'should output the results'
      end

      context 'when a file returns a report with errors' do
        let(:reports) do
          [{}, { error_count: 1 }, {}]
        end
        let(:expected_value) do
          Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
            label:         'ci:rspec_each',
            duration:      6.0,
            error_count:   1,
            failure_count: 0,
            pending_count: 0,
            total_count:   30
          )
        end
        let(:expected_output) do
          <<~RAW
            Running 3 spec files...

            \e[32mPassing\e[0m root_dir/child_spec.rb
            \e[31mErrored\e[0m root_dir/sibling_spec.rb
            \e[32mPassing\e[0m root_spec.rb

            Errored:

            \e[31m  root_dir/sibling_spec.rb\e[0m

            Finished in 6.0 seconds
            \e[31m30 examples, 0 failures, 1 errors\e[0m
          RAW
        end

        it 'should return a passing result' do
          expect(command.call(*arguments, **options))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        include_deferred 'should output the results'
      end

      context 'when a file returns a report with failing specs' do
        let(:reports) do
          [{}, { failure_count: 5 }, {}]
        end
        let(:expected_value) do
          Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
            label:         'ci:rspec_each',
            duration:      6.0,
            error_count:   0,
            failure_count: 5,
            pending_count: 0,
            total_count:   30
          )
        end
        let(:expected_output) do
          <<~RAW
            Running 3 spec files...

            \e[32mPassing\e[0m root_dir/child_spec.rb
            \e[31mFailing\e[0m root_dir/sibling_spec.rb
            \e[32mPassing\e[0m root_spec.rb

            Failures:

            \e[31m  root_dir/sibling_spec.rb\e[0m

            Finished in 6.0 seconds
            \e[31m30 examples, 5 failures\e[0m
          RAW
        end

        it 'should return a passing result' do
          expect(command.call(*arguments, **options))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        include_deferred 'should output the results'
      end

      context 'when a file returns a report with pending specs' do
        let(:reports) do
          [{}, { pending_count: 5 }, {}]
        end
        let(:expected_value) do
          Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
            label:         'ci:rspec_each',
            duration:      6.0,
            error_count:   0,
            failure_count: 0,
            pending_count: 5,
            total_count:   30
          )
        end
        let(:expected_output) do
          <<~RAW
            Running 3 spec files...

            \e[32mPassing\e[0m root_dir/child_spec.rb
            \e[33mPending\e[0m root_dir/sibling_spec.rb
            \e[32mPassing\e[0m root_spec.rb

            Pending:

            \e[33m  root_dir/sibling_spec.rb\e[0m

            Finished in 6.0 seconds
            \e[33m30 examples, 0 failures, 5 pending\e[0m
          RAW
        end

        it 'should return a passing result' do
          expect(command.call(*arguments, **options))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        include_deferred 'should output the results'
      end

      context 'when multiple files report unsuccessful specs' do
        let(:reports) do
          [
            { failure_count: 10 },
            { failure_count: 5, pending_count: 5 },
            { pending_count: 5 }
          ]
        end
        let(:expected_value) do
          Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
            label:         'ci:rspec_each',
            duration:      6.0,
            error_count:   0,
            failure_count: 15,
            pending_count: 10,
            total_count:   30
          )
        end
        let(:expected_output) do
          <<~RAW
            Running 3 spec files...

            \e[31mFailing\e[0m root_dir/child_spec.rb
            \e[31mFailing\e[0m root_dir/sibling_spec.rb
            \e[33mPending\e[0m root_spec.rb

            Pending:

            \e[33m  root_spec.rb\e[0m

            Failures:

            \e[31m  root_dir/child_spec.rb\e[0m
            \e[31m  root_dir/sibling_spec.rb\e[0m

            Finished in 6.0 seconds
            \e[31m30 examples, 15 failures, 10 pending\e[0m
          RAW
        end

        it 'should return a passing result' do
          expect(command.call(*arguments, **options))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        include_deferred 'should output the results'
      end
    end

    describe 'with file_patterns: value' do
      let(:file_patterns) { ['root_dir/*', '**/sibling_spec.rb'] }
      let(:arguments)     { [*super(), *file_patterns] }

      context 'when there are no matching spec files' do
        let(:expected_value) do
          Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
            label:         'ci:rspec_each',
            duration:      0.0,
            error_count:   0,
            failure_count: 0,
            pending_count: 0,
            total_count:   0
          )
        end
        let(:expected_output) do
          <<~RAW
            Running 0 spec files...

            Finished in 0.0 seconds
            \e[33m0 examples, 0 failures\e[0m
          RAW
        end

        it 'should return a passing result' do
          expect(command.call)
            .to be_a_passing_result
            .with_value(expected_value)
        end

        it 'should not call an RSpec command' do
          command.call

          expect(rspec_command).not_to have_received(:call)
        end

        include_deferred 'should output the results'
      end

      context 'when there are matching spec files' do # rubocop:disable RSpec/MultipleMemoizedHelpers
        let(:files) do
          {
            'root_dir'        => {
              'child_spec.rb'   => StringIO.new,
              'sibling_spec.rb' => StringIO.new
            },
            'root_spec.rb'    => StringIO.new,
            'sibling_spec.rb' => StringIO.new
          }
        end
        let(:file_system) do
          Cuprum::Cli::Dependencies::FileSystem::Mock.new(files:)
        end
        let(:reports) do
          Array.new(3) { {} }
        end
        let(:rspec_results) do
          reports.map do |properties|
            report = Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
              label:         'ci:rspec',
              duration:      2.0,
              error_count:   0,
              failure_count: 0,
              pending_count: 0,
              total_count:   10,
              **properties
            )

            Cuprum::Result.new(value: report)
          end
        end
        let(:expected_value) do
          Cuprum::Cli::Commands::Ci::RSpecCommand::Report.new(
            label:         'ci:rspec_each',
            duration:      6.0,
            error_count:   0,
            failure_count: 0,
            pending_count: 0,
            total_count:   30
          )
        end
        let(:expected_files) do
          [
            'root_dir/child_spec.rb',
            'root_dir/sibling_spec.rb',
            'sibling_spec.rb'
          ].map { |file| "#{file_system.root_path}/#{file}" }
        end
        let(:expected_output) do
          <<~RAW
            Running 3 spec files...

            \e[32mPassing\e[0m root_dir/child_spec.rb
            \e[32mPassing\e[0m root_dir/sibling_spec.rb
            \e[32mPassing\e[0m sibling_spec.rb

            Finished in 6.0 seconds
            \e[32m30 examples, 0 failures\e[0m
          RAW
        end

        it 'should return a passing result' do
          expect(command.call(*arguments, **options))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        include_deferred 'should call the RSpec command for each file'

        include_deferred 'should output the results'
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
