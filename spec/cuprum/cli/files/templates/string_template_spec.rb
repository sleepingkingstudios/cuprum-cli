# frozen_string_literal: true

require 'cuprum/cli/files/templates/string_template'

RSpec.describe Cuprum::Cli::Files::Templates::StringTemplate do
  subject(:template) { described_class.new(raw_template:, **options) }

  let(:raw_template) do
    <<~MARKDOWN
      # Greetings, Starfighter

      You have been recruited by the Star League to defend the frontier
      against Xur and the Ko-Dan armada!
    MARKDOWN
  end
  let(:options) { {} }

  describe '.members' do
    let(:expected) { %i[engine raw_template] }

    it { expect(described_class.members).to be == expected }
  end

  describe '#call' do
    it { expect(template).to respond_to(:call).with(0).arguments }

    it 'should return a passing result' do
      expect(template.call)
        .to be_a_passing_result
        .with_value(raw_template)
    end
  end

  describe '#engine' do
    include_examples 'should define reader', :engine, nil

    context 'when initialized with engine: value' do
      let(:engine)  { :erb }
      let(:options) { super().merge(engine:) }

      it { expect(template.engine).to be engine }
    end
  end

  describe '#raw_template' do
    include_examples 'should define reader', :raw_template, -> { raw_template }
  end
end
