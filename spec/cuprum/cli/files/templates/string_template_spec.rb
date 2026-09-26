# frozen_string_literal: true

require 'cuprum/cli/files/templates/string_template'
require 'cuprum/cli/rspec/deferred/templates_examples'

RSpec.describe Cuprum::Cli::Files::Templates::StringTemplate do
  include Cuprum::Cli::RSpec::Deferred::TemplatesExamples

  subject(:template) { described_class.new(raw_template:, **options) }

  let(:raw_template) do
    <<~MARKDOWN
      # Greetings, Starfighter

      You have been recruited by the Star League to defend the frontier
      against Xur and the Ko-Dan armada!
    MARKDOWN
  end
  let(:options) { {} }

  describe '.build' do
    it { expect(described_class).to respond_to(:build).with(1).argument }

    it 'should build a StringTemplate with engine: nil' do
      expect(described_class.build(raw_template))
        .to be_a(described_class)
        .and have_attributes(engine: nil, raw_template:)
    end
  end

  describe '.members' do
    let(:expected) { %i[engine raw_template] }

    it { expect(described_class.members).to be == expected }
  end

  include_deferred 'should implement the Template interface'

  describe '#call' do
    let(:raw_value)      { 'Greetings, programs!' }
    let(:raw_template)   { raw_value }
    let(:expected_value) { raw_value }

    it 'should return a passing result with the rendered template' do
      expect(template.call)
        .to be_a_passing_result
        .with_value(raw_value)
    end

    describe 'with parameters' do
      let(:parameters) { { extra_parameter: 'extra value' } }

      it 'should return a passing result with the rendered template' do
        expect(template.call(**parameters))
          .to be_a_passing_result
          .with_value(raw_value)
      end
    end

    include_deferred 'should apply the configured engine'
  end

  describe '#raw_template' do
    include_examples 'should define reader', :raw_template, -> { raw_template }
  end

  describe '#raw_value' do
    it { expect(template.send(:raw_value)).to be raw_template }
  end
end
