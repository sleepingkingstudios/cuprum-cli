# frozen_string_literal: true

require 'cuprum/cli/integrations/thor/arguments_parser'

RSpec.describe Cuprum::Cli::Integrations::Thor::ArgumentsParser do
  subject(:parser) { described_class.new }

  describe '#call' do
    let(:inputs)    { [] }
    let(:arguments) { inputs.reject { |str| str.start_with?('-') } }
    let(:options)   { {} }
    let(:expected)  { [arguments, options] }

    it { expect(parser).to respond_to(:call).with_unlimited_arguments }

    describe 'with no inputs' do
      it { expect(parser.call(*inputs)).to be == expected }
    end

    describe 'with positional arguments' do
      let(:inputs) { %w[lib/file.rb spec/file_spec.rb] }

      it { expect(parser.call(*inputs)).to be == expected }
    end

    describe 'with individual flags' do
      let(:inputs)  { %w[-a -b --alpha --beta] }
      let(:options) { { a: true, alpha: true, b: true, beta: true } }

      it { expect(parser.call(*inputs)).to be == expected }
    end

    describe 'with grouped short flags' do
      let(:inputs)  { %w[-def] }
      let(:options) { { d: true, e: true, f: true } }

      it { expect(parser.call(*inputs)).to be == expected }
    end

    describe 'with negated flags' do
      let(:inputs)  { %w[--no-gamma --skip-delta] }
      let(:options) { { gamma: false, delta: false } }

      it { expect(parser.call(*inputs)).to be == expected }
    end

    describe 'with options' do
      let(:inputs) do
        %w[-g=true --epsilon=false -n=0 --default=nil --password=secret]
      end
      let(:options) do
        { g: true, epsilon: false, n: 0, default: nil, password: 'secret' }
      end

      it { expect(parser.call(*inputs)).to be == expected }
    end

    describe 'with mixed arguments and options' do
      let(:inputs) do
        %w[-def lib/file.rb --no-flag --password=secret spec/file_spec.rb]
      end
      let(:options) do
        { d: true, e: true, f: true, flag: false, password: 'secret' }
      end

      it { expect(parser.call(*inputs)).to be == expected }
    end
  end
end
