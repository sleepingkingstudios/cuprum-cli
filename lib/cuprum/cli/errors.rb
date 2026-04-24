# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Namespace for errors, which represent failure states of commands.
  module Errors
    autoload :Files,                'cuprum/cli/errors/files'
    autoload :SystemCommandFailure, 'cuprum/cli/errors/system_command_failure'
  end
end
