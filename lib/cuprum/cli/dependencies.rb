# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Dependencies provide standard functionality to commands.
  module Dependencies
    autoload :StandardIo, 'cuprum/cli/dependencies/standard_io'
  end
end
