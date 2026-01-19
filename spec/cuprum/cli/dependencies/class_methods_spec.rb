# frozen_string_literal: true

require 'plumbum/consumer'

require 'cuprum/cli/dependencies'

RSpec.describe Cuprum::Cli::Dependencies::ClassMethods do
  subject(:consumer) { described_class.new }

  let(:described_class) { Spec::Consumer }

  example_class 'Spec::Consumer' do |klass|
    klass.include Plumbum::Consumer
    klass.extend  Cuprum::Cli::Dependencies::ClassMethods # rubocop:disable RSpec/DescribedClass
  end

  describe '#ask' do
    it { expect(consumer).not_to respond_to(:ask) }

    context 'when the class defines a :standard_io dependency' do
      before(:example) { described_class.dependency :standard_io }

      it 'should define the delegated method' do
        expect(consumer)
          .to respond_to(:ask)
          .with(0..1).arguments
          .and_keywords(:caret, :format, :strip)
          .and_any_keywords
      end
    end
  end

  describe '#say' do
    it { expect(consumer).not_to respond_to(:say) }

    context 'when the class defines a :standard_io dependency' do
      before(:example) { described_class.dependency :standard_io }

      it 'should define the delegated method' do
        expect(consumer)
          .to respond_to(:say)
          .with(1).argument
          .and_keywords(:newline)
          .and_any_keywords
      end
    end
  end

  describe '#warn' do
    it { expect(consumer).not_to respond_to(:warn) }

    context 'when the class defines a :standard_io dependency' do
      before(:example) { described_class.dependency :standard_io }

      it 'should define the delegated method' do
        expect(consumer)
          .to respond_to(:warn)
          .with(1).argument
          .and_keywords(:newline)
          .and_any_keywords
      end
    end
  end
end
