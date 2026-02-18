# frozen_string_literal: true

require 'cuprum/cli/integrations'

module Cuprum::Cli::Integrations
  # Integration with the Thor CLI toolkit.
  #
  # @see http://whatisthor.com/
  module Thor
    autoload :Task, 'cuprum/cli/integrations/thor/task'
  end
end
