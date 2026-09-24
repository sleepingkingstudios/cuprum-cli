# frozen_string_literal: true

require 'cuprum/result_helpers'

require 'cuprum/cli/files'

module Cuprum::Cli::Files
  # Data class representing a file generator template.
  Template =
    SleepingKingStudios::Tools::Toolbox::HeritableData.define(:engine) do
      include Cuprum::ResultHelpers

      # @param engine [Symbol] the engine used to generate the template
      #   contents.
      def initialize(engine: nil, **)
        super
      end

      # @return [Cuprum::Result] a result with the raw template, or a result
      #   with an error if unable to return the template contents.
      def call
        error = Cuprum::Errors::CommandNotImplemented.new(command: self)

        failure(error)
      end
    end
end
