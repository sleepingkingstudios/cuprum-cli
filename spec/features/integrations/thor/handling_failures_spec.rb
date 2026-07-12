# frozen_string_literal: true

require 'open3'

require 'cuprum/cli'
require 'cuprum/cli/integrations/thor'

RSpec.describe Cuprum::Cli::Integrations::Thor::Task, integration: :thor do
  let(:command) { "bundle exec ruby #{fixture_file}" }

  context 'when the command raises an exception' do
    let(:fixture_file) do
      'spec/features/integrations/thor/handling_failures_spec.' \
        'unhandled_exception_fixture.rb'
    end
    let(:expected_output) do
      <<~TEXT
        Spec::FailureCommand failed with exception: Something went wrong (RuntimeError)
      TEXT
    end
    let(:expected_backtrace) do
      <<~TEXT
        \tspec/features/integrations/thor/handling_failures_spec.unhandled_exception_fixture.rb:23:in '<main>'
      TEXT
    end

    it 'should apply the deferred examples', :aggregate_failures do
      output, status = Open3.capture2e(command)

      expect(output.lines.first).to be == expected_output
      expect(output.lines.last).to be == expected_backtrace
      expect(status.exitstatus).to be 1
    end
  end

  context 'when the command returns a result without an error message' do
    let(:fixture_file) do
      'spec/features/integrations/thor/handling_failures_spec.' \
        'without_message_fixture.rb'
    end
    let(:expected_output) do
      <<~TEXT
        Spec::FailureCommand failed but did not return an error message.
      TEXT
    end

    it 'should apply the deferred examples', :aggregate_failures do
      output, status = Open3.capture2e(command)

      expect(output).to be == expected_output
      expect(status.exitstatus).to be 1
    end
  end

  context 'when the command returns a result with an error message' do
    let(:fixture_file) do
      'spec/features/integrations/thor/handling_failures_spec.' \
        'with_message_fixture.rb'
    end
    let(:expected_output) do
      <<~TEXT
        Spec::FailureCommand failed with error Cuprum::Error: Something went wrong.
      TEXT
    end

    it 'should apply the deferred examples', :aggregate_failures do
      output, status = Open3.capture2e(command)

      expect(output).to be == expected_output
      expect(status.exitstatus).to be 1
    end
  end
end
