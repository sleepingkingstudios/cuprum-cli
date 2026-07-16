# frozen_string_literal: true

require 'cuprum/cli/files/generators/ruby_generator'

require 'cuprum/cli/rspec/deferred/generators_examples'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Files::Generators::RubyGenerator do
  include Cuprum::Cli::RSpec::Deferred::GeneratorsExamples
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:generator) { described_class.new(file_path, **constructor_options) }

  let(:file_path)           { 'lib/path/to/file.rb' }
  let(:constructor_options) { {} }

  include_deferred 'should define option', :parent_class, type: :string

  include_deferred 'should define option',
    :rspec,
    type:    :boolean,
    default: true,
    aliases: %i[spec]

  include_deferred 'should define option',
    :rspec_template,
    type: :string

  include_deferred 'should define option',
    :ruby,
    type:    :boolean,
    default: true

  include_deferred 'should define option',
    :ruby_template,
    type: :string

  describe '.matches?' do
    it { expect(described_class.matches?('docs/file.md')).to be false }

    it { expect(described_class.matches?('lib/file.rb')).to be true }

    it { expect(described_class.matches?('spec/file_spec.rb')).to be true }
  end

  include_deferred 'should output file',
    '%<file_path>s',
    as:                    :ruby,
    template:              File.join(
      Cuprum::Cli::Files::Generators::TEMPLATES_PATH,
      'ruby.rb.erb'
    ),
    allow_skip:            true,
    allow_custom_template: true

  include_deferred 'should output file',
    File.join('spec', '%<relative_path>s', '%<short_name>s_spec.rb'),
    as:                    :rspec,
    template:              File.join(
      Cuprum::Cli::Files::Generators::TEMPLATES_PATH,
      'rspec.rb.erb'
    ),
    allow_skip:            true,
    allow_custom_template: true
end
