# frozen_string_literal: true

require 'cuprum/cli/files/template'

RSpec.describe Cuprum::Cli::Files::Template do
  subject(:template) { described_class.new(**options) }

  let(:options) { {} }

  describe '.members' do
    let(:expected) { %i[engine] }

    it { expect(described_class.members).to be == expected }
  end

  describe '#call' do
    let(:expected_error) do
      Cuprum::Errors::CommandNotImplemented.new(command: template)
    end

    it { expect(template).to respond_to(:call).with(0).arguments }

    it 'should return a failing result' do
      expect(template.call)
        .to be_a_failing_result
        .with_error(expected_error)
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
end
