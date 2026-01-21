# frozen_string_literal: true

require 'cuprum/cli/option'
require 'cuprum/cli/options'

module Cuprum::Cli::Options
  # Methods used to extend command functionality for defining options.
  module ClassMethods
    # @overload option(name, aliases: [], default: nil, description: nil, required: false, type: :string)
    #   Defines an option for the command class.
    #
    #   @param name [String, Symbol] the name of the option.
    #   @param aliases [Array<String, Symbol>] aliases for the option when
    #     parsing options from the command line.
    #   @param default [Object, Proc] the default value for the option. If given
    #     and the value of the option is nil, sets the option value to the
    #     default value.
    #   @param description [String] a short, human-readable description of the
    #     option.
    #   @param required [true, false] if true, raises an exception if the option
    #     is not provided to the command.
    #   @param type [Class, String, Symbol] the expected type of the option
    #     value as a Class or class name. If given, raises an exception if the
    #     option value is not an instance of the type. Defaults to :string.
    def option(name, **)
      option = Cuprum::Cli::Option.new(name:, **)

      defined_options[option.name] = option

      option.name
    end

    # The defined options, including options defined on ancestor classes.
    #
    # @return [Hash{Symbol => Cuprum::Cli::Option}] the defined options.
    def options
      ancestors.reduce({}) do |hsh, ancestor|
        return hsh if     ancestor == Cuprum::Cli::Command
        next   hsh unless ancestor.respond_to?(:defined_options, true)

        hsh.merge(ancestor.defined_options)
      end
    end

    protected

    def defined_options
      @defined_options ||= {}
    end
  end
end
