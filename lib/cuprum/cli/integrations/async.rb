# frozen_string_literal: true

require 'cuprum/cli/integrations'

module Cuprum::Cli::Integrations
  # Integration with the Async library.
  #
  # @see https://socketry.github.io/async/
  module Async
    autoload :Commands, 'cuprum/cli/integrations/async/commands'

    class << self
      # @return [Integer] The recommended maximum number of concurrent Async
      #   tasks. This value can be configured by setting an
      #   ASYNC_CONCURRENT_TASKS environment variable. The default value is 8.
      def max_concurrent_tasks
        [ENV.fetch('ASYNC_CONCURRENT_TASKS', '8').to_i, 1].max
      end
    end
  end
end
