# frozen_string_literal: true

require 'cuprum/cli/files'

module Cuprum::Cli::Files
  # Namespace for commands that process raw templates into file contents.
  module Engines
    class << self
      # @overload fetch(engine)
      #   Retrieves the render command for the given engine.
      #
      #   @param engine [String] the engine identifier.
      #
      #   @return [Cuprum::Command] the render command for the engine.
      #
      #   @raise [KeyError] if there is no matching engine.
      #
      # @overload fetch(engine, default)
      #   Retrieves the render command for the given engine.
      #
      #   @param engine [String] the engine identifier.
      #   @param default [Cuprum::Command] the command to return if there is no
      #     matching engine.
      #
      #   @return [Cuprum::Command] the render command for the engine.
      #
      # @overload fetch(engine) { |engine| }
      #   Retrieves the render command for the given engine.
      #
      #   If there is no matching engine. calls the block with the given engine.
      #
      #   @param engine [String] the engine identifier.
      #
      #   @return [Cuprum::Command] the render command for the engine.
      #
      #   @yieldparam engine [String] the engine identifier.
      #
      #   @yieldreturn [Cuprum::Command] the command to return if there is no
      #     matching engine.
      def fetch(engine, default = UNDEFINED, &)
        return engines.fetch(engine, &) if default == UNDEFINED

        engines.fetch(engine, default)
      end

      # Registers a render command for the specified engine.
      #
      # @param engine [String] the engine identifier.
      # @param render_command [Cuprum::Command] the render command for the
      #   engine.
      #
      # @return [void]
      def register(engine, render_command)
        engines[engine] = render_command

        nil
      end

      private

      def default_engines
        { ERB => Cuprum::Cli::Files::Engines::RenderErb }
      end

      def engines = @engines ||= default_engines
    end

    autoload :RenderErb,      'cuprum/cli/files/engines/render_erb'
    autoload :RenderTemplate, 'cuprum/cli/files/engines/render_template'

    # Identifier for ERB files.
    ERB = 'cuprum.cli.files.engines.erb'

    UNDEFINED = SleepingKingStudios::Tools::UNDEFINED
    private_constant :UNDEFINED
  end
end
