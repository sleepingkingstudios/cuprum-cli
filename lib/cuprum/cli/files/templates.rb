# frozen_string_literal: true

require 'cuprum/cli/files'

module Cuprum::Cli::Files
  # Namespace for template files and implementations.
  module Templates
    autoload :StringTemplate, 'cuprum/cli/files/templates/string_template'
  end
end
