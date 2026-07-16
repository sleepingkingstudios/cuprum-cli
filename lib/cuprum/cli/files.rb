# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Namespace for shared functionality for manipulating files.
  module Files
    autoload :GenerateFile, 'cuprum/cli/files/generate_file'
    autoload :Generator,    'cuprum/cli/files/generator'
    autoload :Generators,   'cuprum/cli/files/generators'
    autoload :RenderErb,    'cuprum/cli/files/render_erb'
  end
end
