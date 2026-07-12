# frozen_string_literal: true

require 'cuprum/cli'
require 'cuprum/cli/integrations/thor'

module Spec
  class FailureCommand < Cuprum::Cli::Command
    description 'Raises an exception'

    private

    def process
      raise RuntimeError, 'Something went wrong' # rubocop:disable Style/RedundantException
    end
  end

  Task =
    Cuprum::Cli::Integrations::Thor::Task::Builder
    .new(Spec::FailureCommand)
    .build(full_name: 'spec:failure')
end

Spec::Task.new.invoke('spec:failure')
