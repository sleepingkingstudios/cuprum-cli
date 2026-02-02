# frozen_string_literal: true

require 'cuprum/cli/options'

module Cuprum::Cli::Options
  # Defines --verbose option, which enables optional console outputs.
  module Verbose
    DESCRIPTION = 'Enables optional console outputs.'
    private_constant :DESCRIPTION

    class << self
      private

      def included(other)
        super

        other.option   :verbose,
          type:        :boolean,
          aliases:     :v,
          default:     false,
          description: DESCRIPTION
      end
    end

    # (see Cuprum::Cli::Dependencies::StandardIo::Helpers#say)
    def say(message, verbose: false, **)
      return if verbose && !options.fetch(:verbose, false)

      super
    end
  end
end
