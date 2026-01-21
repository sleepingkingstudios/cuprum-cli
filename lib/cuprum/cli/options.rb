# frozen_string_literal: true

require 'cuprum/cli'

module Cuprum::Cli
  # Namespace for functionality that implements command options.
  module Options
    autoload :ClassMethods, 'cuprum/cli/options/class_methods'
  end
end
