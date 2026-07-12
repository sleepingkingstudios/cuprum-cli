# frozen_string_literal: true

require 'cuprum/cli'
require 'cuprum/cli/integrations/thor'

module Spec
  class FailureCommand < Cuprum::Cli::Command
    description 'Fails without an error message'

    private

    def process
      Cuprum::Result.new(status: :failure)
    end
  end

  Task =
    Cuprum::Cli::Integrations::Thor::Task::Builder
    .new(Spec::FailureCommand)
    .build(full_name: 'spec:failure')
end

Spec::Task.new.invoke('spec:failure')
