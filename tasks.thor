# frozen_string_literal: true

require 'cuprum/cli/integrations/thor/registry'

registry = Cuprum::Cli::Integrations::Thor::Registry.new

registry.register Cuprum::Cli::Commands::Ci::RSpecCommand
registry.register Cuprum::Cli::Commands::Ci::RSpecCommand,
  description: 'Runs the RSpec tests including specs for the Thor integration.',
  full_name:   'ci:rspec:thor',
  options:     {
    env:     { integration: 'thor' },
    gemfile: 'gemfiles/integrations_thor.gemfile'
  }
