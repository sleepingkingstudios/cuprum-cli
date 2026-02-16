# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Namespace for predefined commands.
  module Commands
    autoload :EchoCommand, 'cuprum/cli/commands/echo_command'
  end
end
