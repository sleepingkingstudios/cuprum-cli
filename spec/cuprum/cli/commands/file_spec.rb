# frozen_string_literal: true

require 'cuprum/cli/commands/file'

RSpec.describe Cuprum::Cli::Commands::File do
  describe '.commands' do
    let(:expected) do
      [
        described_class::NewCommand
      ]
    end

    include_examples 'should define class reader', :commands, -> { expected }
  end
end
