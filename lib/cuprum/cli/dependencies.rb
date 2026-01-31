# frozen_string_literal: true

require 'plumbum'

require 'cuprum/cli'

module Cuprum::Cli
  # Dependencies provide standard functionality to commands.
  module Dependencies
    autoload :StandardIo,    'cuprum/cli/dependencies/standard_io'
    autoload :SystemCommand, 'cuprum/cli/dependencies/system_command'

    # @return [Plumbum::Provider] the provider for the standard dependencies.
    def self.provider
      @provider ||= Plumbum::ManyProvider.new(
        values: {
          standard_io:    StandardIo.new,
          system_command: SystemCommand.new
        }
      )
    end
  end
end
