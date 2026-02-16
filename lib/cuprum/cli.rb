# frozen_string_literal: true

require 'cuprum'

require_relative 'cli/version'

module Cuprum
  # Command-line utility powered by Cuprum.
  module Cli
    autoload :Argument,     'cuprum/cli/argument'
    autoload :Arguments,    'cuprum/cli/arguments'
    autoload :Command,      'cuprum/cli/command'
    autoload :Commands,     'cuprum/cli/commands'
    autoload :Dependencies, 'cuprum/cli/dependencies'
    autoload :Errors,       'cuprum/cli/errors'
    autoload :Metadata,     'cuprum/cli/metadata'
    autoload :Option,       'cuprum/cli/option'
    autoload :Options,      'cuprum/cli/options'
    autoload :Registry,     'cuprum/cli/registry'

    # @return [String] the absolute path to the gem directory.
    def self.gem_path
      sep     = File::SEPARATOR
      pattern = /#{sep}lib#{sep}cuprum#{sep}?\z/

      __dir__.sub(pattern, '')
    end

    # @return [String] the current version of the gem.
    def self.version
      Cuprum::Cli::VERSION
    end
  end
end
