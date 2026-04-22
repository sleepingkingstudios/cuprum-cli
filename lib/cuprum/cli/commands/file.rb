# frozen_string_literal: true

require 'cuprum/cli/commands'

module Cuprum::Cli::Commands
  # Namespace for commands that create or manage files.
  module File
    autoload :GenerateFile,    'cuprum/cli/commands/file/generate_file'
    autoload :RenderErb,       'cuprum/cli/commands/file/render_erb'
    autoload :ResolveTemplate, 'cuprum/cli/commands/file/resolve_template'
  end
end
