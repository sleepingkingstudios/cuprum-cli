# frozen_string_literal: true

require 'cuprum/cli/integrations/thor'
require 'cuprum/cli/integrations/thor/task'
require 'cuprum/cli/registry'

module Cuprum::Cli::Integrations::Thor
  # Registers CLI commands by name and adds as Thor tasks.
  class Registry < Cuprum::Cli::Registry
    private

    def add_registered_command(command)
      super

      Cuprum::Cli::Integrations::Thor::Task::Builder
        .new(command)
        .build(full_name: command.full_name)
    end
  end
end
