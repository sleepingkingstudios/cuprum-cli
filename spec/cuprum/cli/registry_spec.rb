# frozen_string_literal: true

require 'cuprum/cli/registry'
require 'cuprum/cli/rspec/deferred/registry_examples'

RSpec.describe Cuprum::Cli::Registry do
  include Cuprum::Cli::RSpec::Deferred::RegistryExamples

  subject(:registry) { described_class.new }

  include_deferred 'should implement the Registry interface'
end
