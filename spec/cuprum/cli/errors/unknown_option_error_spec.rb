# frozen_string_literal: true

require 'cuprum/cli/errors/unknown_option_error'

RSpec.describe Cuprum::Cli::Errors::UnknownOptionError do
  it { expect(described_class).to be_a Class }

  it { expect(described_class).to be < StandardError }
end
