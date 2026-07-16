# frozen_string_literal: true

require 'cuprum/cli/files/generators/rspec_generator'

require 'cuprum/cli/rspec/deferred/generators_examples'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Files::Generators::RSpecGenerator do # rubocop:disable RSpec/SpecFilePathFormat
  include Cuprum::Cli::RSpec::Deferred::GeneratorsExamples
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:generator) { described_class.new(file_path, **constructor_options) }

  let(:file_path)           { 'spec/path/to/file_spec.rb' }
  let(:constructor_options) { {} }

  include_deferred 'should define option',
    :rspec_template,
    type: :string

  describe '.matches?' do
    it { expect(described_class.matches?('docs/file.md')).to be false }

    it { expect(described_class.matches?('lib/file.rb')).to be false }

    it { expect(described_class.matches?('lib/rspec.rb')).to be false }

    it { expect(described_class.matches?('spec/file_spec.rb')).to be true }
  end

  include_deferred 'should output file',
    '%<file_path>s',
    as:                    :rspec,
    template:              File.join(
      Cuprum::Cli::Files::Generators::TEMPLATES_PATH,
      'rspec.rb.erb'
    ),
    allow_skip:            false,
    allow_custom_template: true
end
