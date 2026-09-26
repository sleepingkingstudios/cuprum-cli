# frozen_string_literal: true

require 'cuprum/processing'
require 'sleeping_king_studios/tools/toolbox/heritable_data'

require 'cuprum/cli/files'

module Cuprum::Cli::Files
  # Data class representing a file generator template.
  Template =
    SleepingKingStudios::Tools::Toolbox::HeritableData.define(:engine) do # rubocop:disable Metrics/BlockLength
      include Cuprum::Processing
      include Cuprum::ResultHelpers
      include Cuprum::Steps

      # @param engine [Symbol] the engine used to generate the template
      #   contents.
      def initialize(engine: nil, **)
        super
      end

      # (see Cuprum::Processing#call)
      def call(*args, **kwargs, &)
        steps { super }
      end

      private

      def apply_engine(template, **parameters)
        return template unless engine

        engine_class = Cuprum::Cli::Files::Engines.fetch(engine) do
          return failure(unknown_engine_error)
        end

        engine_class.new(template_name:).call(template, **parameters)
      end

      def process(**parameters)
        template = step { raw_value }

        apply_engine(template, **parameters)
      end

      def raw_value
        error = Cuprum::Errors::CommandNotImplemented.new(command: self)

        failure(error)
      end

      def template_name = nil

      def unknown_engine_error
        details = "unknown template engine #{engine.inspect}"

        Cuprum::Cli::Files::Errors::TemplateError.new(
          details:,
          message: "unable to render template - #{details}"
        )
      end
    end
end
