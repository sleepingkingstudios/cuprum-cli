# frozen_string_literal: true

require 'cuprum/cli/dependencies'

RSpec.describe Cuprum::Cli::Dependencies do
  describe '.provider' do
    let(:provider) { described_class.provider }

    include_examples 'should define class reader',
      :provider,
      -> { be_a Plumbum::ManyProvider }

    it 'should memoize the value' do
      expect(provider).to be described_class.provider
    end

    it 'should provide a StandardIo dependency' do
      expect(provider.get(:standard_io)).to be_a described_class::StandardIo
    end

    it 'should provide a SystemCommand dependency' do
      expect(provider.get(:system_command))
        .to be_a described_class::SystemCommand
    end
  end
end
