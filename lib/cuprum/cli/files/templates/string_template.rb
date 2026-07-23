# frozen_string_literal: true

require 'cuprum/cli/files/template'
require 'cuprum/cli/files/templates'

module Cuprum::Cli::Files::Templates
  # Data class representing a string literal template.
  StringTemplate =
    Cuprum::Cli::Files::Template.define(:raw_template) do
      # (see Cuprum::Cli::Files::Template#call)
      def call = success(raw_template)
    end
end
