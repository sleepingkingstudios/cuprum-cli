# frozen_string_literal: true

require 'cuprum/cli/files'

module Cuprum::Cli::Files
  # Namespace for pre-defined file generators.
  module Generators
    autoload :RubyGenerator, 'cuprum/cli/files/generators/ruby_generator'

    # The path for template files, used when defining generators.
    TEMPLATES_PATH =
      File
      .join(
        Cuprum::Cli.gem_path,
        'lib',
        'cuprum',
        'cli',
        'commands',
        'file',
        'templates'
      )
      .freeze
  end
end
