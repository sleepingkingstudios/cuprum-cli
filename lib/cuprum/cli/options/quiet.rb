# frozen_string_literal: true

require 'cuprum/cli/options'

module Cuprum::Cli::Options
  # Defines --quiet option, which silences non-essential output.
  module Quiet
    DESCRIPTION = 'Silences non-essential console outputs.'
    private_constant :DESCRIPTION

    class << self
      private

      def included(other)
        super

        other.option   :quiet,
          type:        :boolean,
          aliases:     :q,
          default:     false,
          description: DESCRIPTION
      end
    end

    # (see Cuprum::Cli::Dependencies::StandardIo::Helpers#say)
    def say(message, quiet: false, **)
      return if options.fetch(:quiet, false) && !quiet

      super
    end
  end
end
