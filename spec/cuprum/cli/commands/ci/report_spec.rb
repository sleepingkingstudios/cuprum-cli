# frozen_string_literal: true

require 'cuprum/cli/commands/ci/report'
require 'cuprum/cli/rspec/deferred/ci/report_examples'

RSpec.describe Cuprum::Cli::Commands::Ci::Report do
  include Cuprum::Cli::RSpec::Deferred::Ci::ReportExamples

  subject(:report) { described_class.new(**properties) }

  let(:properties) { { duration: 1.0, total_count: 100 } }

  include_deferred 'should define report subclasses'

  include_deferred 'should implement the CI report interface'

  describe '.new' do
    let(:expected_keywords) do
      %i[
        duration
        error_count
        failure_count
        label
        pending_count
        success_count
        total_count
      ]
    end

    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(*expected_keywords)
    end
  end
end
