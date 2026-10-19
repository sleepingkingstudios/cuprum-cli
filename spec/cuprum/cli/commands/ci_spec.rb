# frozen_string_literal: true

require 'cuprum/cli/commands/ci'

RSpec.describe Cuprum::Cli::Commands::Ci do
  describe '.commands' do
    let(:expected) do
      [
        described_class::RSpecCommand,
        described_class::RSpecEachCommand
      ]
    end

    include_examples 'should define class reader', :commands, -> { expected }
  end
end
