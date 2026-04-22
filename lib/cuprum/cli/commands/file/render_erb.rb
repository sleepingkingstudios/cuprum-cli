# frozen_string_literal: true

require 'cuprum/command'
require 'herb'

require 'cuprum/cli/commands/file'
require 'cuprum/cli/errors/files/missing_parameter'

module Cuprum::Cli::Commands::File
  # Utility command for generating file contents from an .erb template.
  class RenderErb < Cuprum::Command
    class RenderingContext < BasicObject; end
    private_constant :RenderingContext

    # @param template_name [String, nil] the name of the rendered template. Used
    #   for error reporting.
    def initialize(template_name: nil)
      super()

      @template_name = template_name
    end

    # @return [String, nil] the name of the rendered template.
    attr_reader :template_name

    private

    def compilation_error(details)
      message = 'unable to render ERB template'
      message = "#{message} #{template_name}" if template_name

      Cuprum::Cli::Errors::Files::TemplateError.new(message:, details:)
    end

    def empty_binding = RenderingContext.new.instance_exec { Kernel.binding }

    def generate_binding(**params)
      params.each.with_object(empty_binding) do |(key, value), binding|
        binding.local_variable_set(key, value)
      end
    end

    def generate_engine(template)
      Herb::Engine.new(template)
    rescue Herb::Engine::CompilationError,
           Herb::Engine::SecurityError => exception
      error = compilation_error(exception.message)

      failure(error)
    end

    def missing_parameter_error(parameter_name)
      Cuprum::Cli::Errors::Files::MissingParameter.new(
        message:        'unable to render ERB template',
        parameter_name:,
        template_name:
      )
    end

    def process(template, **params) # rubocop:disable Metrics/MethodLength
      engine  = step { generate_engine(template) }
      binding = generate_binding(**params)

      binding.eval(engine.src)
    rescue NameError => exception
      error =
        if exception.message.end_with?(RenderingContext.name)
          missing_parameter_error(exception.name)
        else
          template_error(exception.message)
        end

      failure(error)
    end

    def template_error(message)
      Cuprum::Cli::Errors::Files::TemplateError.new(
        message:       "unable to render ERB template - #{message}",
        template_name:
      )
    end
  end
end
