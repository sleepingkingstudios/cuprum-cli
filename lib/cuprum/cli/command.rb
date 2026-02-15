# frozen_string_literal: true

require 'cuprum'
require 'plumbum'

require 'cuprum/cli'

module Cuprum::Cli
  # Abstract base class for defining CLI commands.
  class Command < Cuprum::Command
    include Plumbum::Consumer
    prepend Plumbum::Parameters
    include Cuprum::Cli::Metadata
    extend  Cuprum::Cli::Arguments::ClassMethods
    extend  Cuprum::Cli::Options::ClassMethods

    # Exception raised when defining an argument or  option directly on Command.
    class AbstractCommandError < StandardError; end

    provider Cuprum::Cli::Dependencies.provider

    class << self
      # (see Cuprum::Cli::Arguments::ClassMethods#argument)
      def argument(argument_name, **)
        return super unless abstract?

        raise AbstractCommandError,
          "unable to define argument :#{argument_name} - #{name} is an " \
          'abstract class'
      end

      # (see Cuprum::Cli::Dependencies::ClassMethods#dependency)
      def dependency(dependency_name, **)
        return super unless abstract?

        raise AbstractCommandError,
          "unable to add dependency :#{dependency_name} - #{name} is an " \
          'abstract class'
      end

      # (see Cuprum::Cli::Dependencies::ClassMethods#option)
      def option(option_name, **)
        return super unless abstract?

        raise AbstractCommandError,
          "unable to define option :#{option_name} - #{name} is an abstract " \
          'class'
      end

      private

      def abstract? = self == Cuprum::Cli::Command
    end

    def initialize(**)
      super

      @arguments = {}
      @options   = {}
    end

    # @todo
    def call(*, resolved_arguments: nil, resolved_options: nil, **)
      @arguments =
        resolved_arguments || self.class.resolve_arguments(*)
      @options   =
        resolved_options   || self.class.resolve_options(**)

      super()
    end

    private

    attr_reader :arguments

    attr_reader :options

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
