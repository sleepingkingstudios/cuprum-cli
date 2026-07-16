# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Namespace for shared functionality for manipulating files.
  module Files
    autoload :Generator,  'cuprum/cli/files/generator'
    autoload :Generators, 'cuprum/cli/files/generators'
  end
end
