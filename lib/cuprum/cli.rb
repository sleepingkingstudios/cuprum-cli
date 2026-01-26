# frozen_string_literal: true

require 'cuprum'

require_relative 'cli/version'

module Cuprum
  # Command-line utility powered by Cuprum.
  module Cli
    autoload :Argument,     'cuprum/cli/argument'
    autoload :Arguments,    'cuprum/cli/arguments'
    autoload :Command,      'cuprum/cli/command'
    autoload :Dependencies, 'cuprum/cli/dependencies'
    autoload :Option,       'cuprum/cli/option'
    autoload :Options,      'cuprum/cli/options'
  end
end
