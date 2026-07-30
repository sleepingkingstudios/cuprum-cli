# frozen_string_literal: true

require 'cuprum/cli/files/template'
require 'cuprum/cli/files/templates'

module Cuprum::Cli::Files::Templates
  # Data class representing a string literal template.
  StringTemplate = Cuprum::Cli::Files::Template.define(:raw_template) do
    class_methods = Module.new do
      # Converts a raw template string to a template object.
      #
      # @param raw_template [String] the unprocessed template string.
      #
      # @return [StringTemplate] the generated template.
      def build(raw_template) = new(engine: nil, raw_template:)
    end
    const_set(:ClassMethods, class_methods)

    def self.included(other)
      super

      other.extend(const_get(:ClassMethods))
    end

    # (see Cuprum::Cli::Files::Template#call)
    def call = success(raw_template)
  end
end
