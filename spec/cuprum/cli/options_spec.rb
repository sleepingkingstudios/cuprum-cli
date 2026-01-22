# frozen_string_literal: true

require 'cuprum/cli/options'

RSpec.describe Cuprum::Cli::Options do
  describe '::InvalidOptionError' do
    include_examples 'should define constant',
      :InvalidOptionError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::UnknownOptionError' do
    include_examples 'should define constant',
      :UnknownOptionError,
      -> { be_a(Class).and(be < StandardError) }
  end
end
