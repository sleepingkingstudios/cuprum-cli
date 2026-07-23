# frozen_string_literal: true

require 'cuprum/cli/integrations/async'

RSpec.describe Cuprum::Cli::Integrations::Async do
  describe '.max_concurrent_tasks' do
    let(:configured_value) { nil }

    around(:example) do |example|
      wrap_env('ASYNC_CONCURRENT_TASKS', configured_value) { example.call }
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:max_concurrent_tasks)
        .with(0).arguments
    end

    it { expect(described_class.max_concurrent_tasks).to be 8 }

    context 'when ASYNC_CONCURRENT_TASKS is set to zero' do
      let(:configured_value) { '0' }

      it { expect(described_class.max_concurrent_tasks).to be 1 }
    end

    context 'when ASYNC_CONCURRENT_TASKS is set to a positive integer' do
      let(:configured_value) { '65536' }

      it { expect(described_class.max_concurrent_tasks).to be 65_536 }
    end
  end
end
