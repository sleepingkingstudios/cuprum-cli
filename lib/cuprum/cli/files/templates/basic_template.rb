# frozen_string_literal: true

require 'cuprum/cli/files/templates'

module Cuprum::Cli::Files::Templates
  # Data class representing a template that returns the input contents.
  BasicTemplate = Cuprum::Cli::Files::Template.define do
    private

    def process(contents: nil, **parameters)
      step { validate_contents(contents) }

      apply_engine(contents, **parameters)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    def validate_contents(contents) # rubocop:disable Metrics/MethodLength
      validator = tools.assertions.aggregator_class.new

      validator.validate_presence(contents, as: 'contents')
      validator.validate_instance_of(
        contents,
        as:       'contents',
        expected: String
      )

      return Cuprum::Result.new if validator.empty?

      error = Cuprum::Errors::InvalidParameters.new(
        command_class: self.class,
        failures:      validator.each.to_a
      )
      failure(error)
    end
  end
end
