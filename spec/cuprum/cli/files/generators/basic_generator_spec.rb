# frozen_string_literal: true

require 'cuprum/cli/files/generators/basic_generator'
require 'cuprum/cli/rspec/deferred/generators_examples'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Files::Generators::BasicGenerator do
  include Cuprum::Cli::RSpec::Deferred::GeneratorsExamples
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:generator) do
    described_class.new(file_system:, standard_io:, **options)
  end

  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new }
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }
  let(:file_path)   { 'lib/path/to/file.rb' }
  let(:contents) do
    <<~TEXT
      # Greetings, Starfighter!

      You have been recruited by the Star League to defend the frontier against
      Xur and the Ko-Dan Armada!
    TEXT
  end
  let(:options)           { { contents:, file_path: } }
  let(:expected_contents) { contents }

  include_deferred 'should define option',
    :contents,
    type:     :string,
    required: true

  include_deferred 'should define option',
    :file_path,
    type:     :string,
    required: true

  include_deferred 'should output file', 'lib/path/to/file.rb'
end
