# frozen_string_literal: true

require 'cuprum/cli/arguments'

RSpec.describe Cuprum::Cli::Arguments do
  describe '::ExtraArgumentsError' do
    include_examples 'should define constant',
      :ExtraArgumentsError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::InvalidArgumentError' do
    include_examples 'should define constant',
      :InvalidArgumentError,
      -> { be_a(Class).and(be < StandardError) }
  end
end
