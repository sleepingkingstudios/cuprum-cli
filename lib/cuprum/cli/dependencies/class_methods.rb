# frozen_string_literal: true

require 'cuprum/cli/dependencies'

module Cuprum::Cli::Dependencies
  STANDARD_DEPENDENCIES = {
    standard_io: 'StandardIo'
  }.freeze
  private_constant :STANDARD_DEPENDENCIES

  # Class methods for extending dependencies.
  module ClassMethods
    # @overload dependency(*keys, **options)
    #   Defines dependencies and delegated methods.
    #
    #   If any of the dependencies matches a standard Cuprum::Cli command
    #   dependency, additionally delegates the :delegated_methods for that
    #   dependency.
    #
    # @param keys [Array<String, Symbol>] the dependencies to define.
    # @param options [Hash] options for defining the dependencies.
    #
    # @see Plumbum::Consumer::ClassMethods#dependencies.
    def dependency(*keys, **)
      super

      keys.each do |key|
        next unless STANDARD_DEPENDENCIES.key?(key.to_sym)

        super(*delegated_methods_for(key.to_sym), scope: key)
      end
    end

    private

    def delegated_methods_for(module_name)
      dependency =
        Cuprum::Cli::Dependencies
        .const_get(STANDARD_DEPENDENCIES[module_name])

      dependency.delegated_methods
    end
  end
end
