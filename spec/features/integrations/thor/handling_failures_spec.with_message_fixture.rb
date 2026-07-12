# frozen_string_literal: true

require 'cuprum/cli'
require 'cuprum/cli/integrations/thor'

module Spec
  class FailureCommand < Cuprum::Cli::Command
    description 'Fails with an error message'

    private

    def process
      error = Cuprum::Error.new(message: 'Something went wrong')

      failure(error)
    end
  end

  Task =
    Cuprum::Cli::Integrations::Thor::Task::Builder
    .new(Spec::FailureCommand)
    .build(full_name: 'spec:failure')
end

Spec::Task.new.invoke('spec:failure')
