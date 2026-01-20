# frozen_string_literal: true

require 'plumbum'

require 'cuprum/cli'

module Cuprum::Cli
  # Dependencies provide standard functionality to commands.
  module Dependencies
    autoload :StandardIo, 'cuprum/cli/dependencies/standard_io'

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

    # @return [Plumbum::Provider] the provider for the standard dependencies.
    def self.provider
      @provider ||= Plumbum::ManyProvider.new(
        values: { standard_io: StandardIo.new }
      )
    end
  end
end
