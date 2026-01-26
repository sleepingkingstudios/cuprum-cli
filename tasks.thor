# frozen_string_literal: true

require 'byebug'

require 'cuprum/cli/integrations/thor/registry'

registry = Cuprum::Cli::Integrations::Thor::Registry.new

registry.register Cuprum::Cli::Commands::EchoCommand
