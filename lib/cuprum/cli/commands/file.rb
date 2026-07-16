# frozen_string_literal: true

require 'cuprum/cli/commands'

module Cuprum::Cli::Commands
  # Namespace for commands that create or manage files.
  module File
    autoload :NewCommand, 'cuprum/cli/commands/file/new_command'
  end
end
