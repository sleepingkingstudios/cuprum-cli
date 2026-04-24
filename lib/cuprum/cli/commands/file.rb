# frozen_string_literal: true

require 'cuprum/cli/commands'

module Cuprum::Cli::Commands
  # Namespace for commands that create or manage files.
  module File
    autoload :GenerateFile,    'cuprum/cli/commands/file/generate_file'
    autoload :NewCommand,      'cuprum/cli/commands/file/new_command'
    autoload :RenderErb,       'cuprum/cli/commands/file/render_erb'
    autoload :ResolveTemplate, 'cuprum/cli/commands/file/resolve_template'
    autoload :Templates,       'cuprum/cli/commands/file/templates'
  end
end
