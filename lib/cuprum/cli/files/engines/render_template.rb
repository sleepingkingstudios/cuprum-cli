# frozen_string_literal: true

require 'plumbum'

require 'cuprum/cli/files/engines'

module Cuprum::Cli::Files::Engines
  # Generates the contents of the given template.
  class RenderTemplate < Cuprum::Command
    include Plumbum::Consumer
    prepend Plumbum::Parameters

    dependency :file_system

    provider Cuprum::Cli::Dependencies.provider

    private

    def process(template, **parameters)
      if template.members.include?(:file_system)
        template = template.with(file_system:)
      end

      engine       = template.engine
      raw_template = step { template.call }

      render_template(engine:, parameters:, raw_template:)
    end

    def render_template(engine:, parameters:, raw_template:)
      return raw_template if engine.nil?

      command = Cuprum::Cli::Files::Engines.fetch(engine) do
        return failure(unknown_engine_error(engine:))
      end
      command.new.call(raw_template, **parameters)
    end

    def unknown_engine_error(engine:)
      details = "unknown template engine #{engine.inspect}"

      Cuprum::Cli::Files::Errors::TemplateError.new(
        details:,
        message: "unable to render template - #{details}"
      )
    end
  end
end
