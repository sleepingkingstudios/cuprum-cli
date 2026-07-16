# frozen_string_literal: true

require 'cuprum/cli/files/generators'

RSpec.describe Cuprum::Cli::Files::Generators do
  describe '::TEMPLATES_PATH' do
    let(:expected) do
      "#{Cuprum::Cli.gem_path}/lib/cuprum/cli/commands/file/templates"
    end

    include_examples 'should define immutable constant',
      :TEMPLATES_PATH,
      -> { expected }
  end
end
