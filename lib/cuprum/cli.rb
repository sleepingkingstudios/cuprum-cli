# frozen_string_literal: true

require 'cuprum'

require_relative 'cli/version'

module Cuprum
  # Command-line utility powered by Cuprum.
  module Cli
    autoload :Dependencies, 'cuprum/cli/dependencies'
    autoload :Errors,       'cuprum/cli/errors'
    autoload :Option,       'cuprum/cli/option'
  end
end
