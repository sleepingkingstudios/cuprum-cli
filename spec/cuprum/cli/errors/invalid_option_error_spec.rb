# frozen_string_literal: true

require 'cuprum/cli/errors/invalid_option_error'

RSpec.describe Cuprum::Cli::Errors::InvalidOptionError do
  it { expect(described_class).to be_a Class }

  it { expect(described_class).to be < StandardError }
end
