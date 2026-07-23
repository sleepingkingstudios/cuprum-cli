# frozen_string_literal: true

load 'sleeping_king_studios/docs/tasks.rb'

require 'cuprum/cli'

Cuprum::Cli.initializer.call

require 'cuprum/cli/integrations/async'
require 'cuprum/cli/integrations/thor/registry'

registry = Cuprum::Cli::Integrations::Thor::Registry.new

################################################################################
# CI Commands
################################################################################

registry.register Cuprum::Cli::Commands::Ci::RSpecCommand,
  options: {
    gemfile: 'gemfiles/default.gemfile'
  }
registry.register Cuprum::Cli::Commands::Ci::RSpecCommand,
  description: 'Runs the RSpec tests including specs for Async commands.',
  full_name:   'ci:rspec:async',
  options:     {
    env:     { integration: 'async' },
    gemfile: 'gemfiles/integrations_async.gemfile'
  }
registry.register Cuprum::Cli::Commands::Ci::RSpecCommand,
  description: 'Runs the RSpec tests including specs for the Thor integration.',
  full_name:   'ci:rspec:thor',
  options:     {
    env:     { integration: 'thor' },
    gemfile: 'gemfiles/integrations_thor.gemfile'
  }
registry.register Cuprum::Cli::Integrations::Async::Commands::RSpecEachCommand

################################################################################
# File Commands
################################################################################

registry.register Cuprum::Cli::Commands::File::NewCommand
