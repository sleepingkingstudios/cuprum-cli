# frozen_string_literal: true

require 'plumbum'

require 'cuprum/cli'

module Cuprum::Cli
  # Dependencies provide standard functionality to commands.
  module Dependencies
    autoload :ClassMethods, 'cuprum/cli/dependencies/class_methods'
    autoload :StandardIo,   'cuprum/cli/dependencies/standard_io'

    # @return [Plumbum::Provider] the provider for the standard dependencies.
    def self.provider
      @provider ||= Plumbum::ManyProvider.new(
        values: { standard_io: StandardIo.new }
      )
    end
  end
end
