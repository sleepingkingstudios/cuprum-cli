# frozen_string_literal: true

require 'cuprum/cli/coercion'

RSpec.describe Cuprum::Cli::Coercion do
  const_set :DECIMAL_VALUES, %w[0.0 1.0 10.0 1,000.0 1_000.0 -1.0].freeze

  const_set :FALSY_VALUES, %w[f false n no].freeze

  const_set :INTEGER_VALUES, %w[0 1 10 1,000 1_000 -1].freeze

  const_set :NULLISH_VALUES, %w[nil null].freeze

  const_set :TRUTHY_VALUES, %w[t true y yes].freeze

  describe '::CoercionError' do
    include_examples 'should define constant',
      :CoercionError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '.coerce' do
    it { expect(described_class).to respond_to(:coerce).with(1).argument }

    describe 'with nil' do
      let(:value) { nil }

      it { expect(described_class.coerce(nil)).to be nil }
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }

      it { expect(described_class.coerce(value)).to be == value.inspect }
    end

    describe 'with an empty String' do
      let(:value) { '' }

      it { expect(described_class.coerce(value)).to be nil }
    end

    describe 'with a non-empty String' do
      let(:value) { 'Greetings, programs!' }

      it { expect(described_class.coerce(value)).to be value }
    end

    const_get(:DECIMAL_VALUES).each do |decimal_value|
      describe "with value: '#{decimal_value}'" do
        let(:value) { decimal_value }

        it { expect(described_class.coerce(value)).to be value }
      end
    end

    const_get(:FALSY_VALUES).each do |falsy_value|
      describe "with value: '#{falsy_value}'" do
        let(:value) { falsy_value }

        it { expect(described_class.coerce(value)).to be false }
      end
    end

    const_get(:INTEGER_VALUES).each do |integer_value|
      describe "with value: '#{integer_value}'" do
        let(:value)    { integer_value }
        let(:expected) { value.tr('_,', '').to_i }

        it { expect(described_class.coerce(value)).to be == expected }
      end
    end

    const_get(:NULLISH_VALUES).each do |nullish_value|
      describe "with value: '#{nullish_value}'" do
        let(:value) { nullish_value }

        it { expect(described_class.coerce(value)).to be nil }
      end
    end

    const_get(:TRUTHY_VALUES).each do |truthy_value|
      describe "with value: '#{truthy_value}'" do
        let(:value) { truthy_value }

        it { expect(described_class.coerce(value)).to be true }
      end
    end
  end

  describe '.coerce_boolean' do
    let(:error_message) do
      "unable to coerce #{value.inspect} to true or false"
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:coerce_boolean)
        .with(1).argument
        .and_keywords(:skip_validation)
    end

    describe 'with nil' do
      it { expect(described_class.coerce_boolean(nil)).to be false }
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }

      it 'should raise an exception' do
        expect { described_class.coerce_boolean(value) }
          .to raise_error described_class::CoercionError, error_message
      end
    end

    describe 'with an empty String' do
      let(:value) { '' }

      it 'should raise an exception' do
        expect { described_class.coerce_boolean(value) }
          .to raise_error described_class::CoercionError, error_message
      end

      describe 'with skip_validation: true' do
        it 'should return nil' do
          expect(described_class.coerce_boolean(value, skip_validation: true))
            .to be nil
        end
      end
    end

    describe 'with an invalid String' do
      let(:value) { 'Greetings, programs!' }

      it 'should raise an exception' do
        expect { described_class.coerce_boolean(value) }
          .to raise_error described_class::CoercionError, error_message
      end

      describe 'with skip_validation: true' do
        it 'should return nil' do
          expect(described_class.coerce_boolean(value, skip_validation: true))
            .to be nil
        end
      end
    end

    const_get(:FALSY_VALUES).each do |falsy_value|
      describe "with value: '#{falsy_value}'" do
        let(:value) { falsy_value }

        it { expect(described_class.coerce_boolean(value)).to be false }
      end

      describe "with value: '#{falsy_value.upcase}'" do
        let(:value) { falsy_value.upcase }

        it { expect(described_class.coerce_boolean(value)).to be false }
      end
    end

    const_get(:TRUTHY_VALUES).each do |truthy_value|
      describe "with value: '#{truthy_value}'" do
        let(:value) { truthy_value }

        it { expect(described_class.coerce_boolean(value)).to be true }
      end

      describe "with value: '#{truthy_value.upcase}'" do
        let(:value) { truthy_value.upcase }

        it { expect(described_class.coerce_boolean(value)).to be true }
      end
    end
  end

  describe '.coerce_boolean?' do
    it 'should define the class predicate' do
      expect(described_class).to respond_to(:coerce_boolean?).with(1).argument
    end

    describe 'with nil' do
      it { expect(described_class.coerce_boolean?(nil)).to be true }
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }

      it { expect(described_class.coerce_boolean?(value)).to be false }
    end

    describe 'with an empty String' do
      let(:value) { '' }

      it { expect(described_class.coerce_boolean?(value)).to be false }
    end

    describe 'with an invalid String' do
      let(:value) { 'Greetings, programs!' }

      it { expect(described_class.coerce_boolean?(value)).to be false }
    end

    const_get(:FALSY_VALUES).each do |falsy_value|
      describe "with value: '#{falsy_value}'" do
        let(:value) { falsy_value }

        it { expect(described_class.coerce_boolean?(value)).to be true }
      end

      describe "with value: '#{falsy_value.upcase}'" do
        let(:value) { falsy_value.upcase }

        it { expect(described_class.coerce_boolean?(value)).to be true }
      end
    end

    const_get(:TRUTHY_VALUES).each do |truthy_value|
      describe "with value: '#{truthy_value}'" do
        let(:value) { truthy_value }

        it { expect(described_class.coerce_boolean?(value)).to be true }
      end

      describe "with value: '#{truthy_value.upcase}'" do
        let(:value) { truthy_value.upcase }

        it { expect(described_class.coerce_boolean?(value)).to be true }
      end
    end
  end

  describe '.coerce_integer' do
    let(:error_message) do
      "unable to coerce #{value.inspect} to an Integer"
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:coerce_integer)
        .with(1).argument
        .and_keywords(:skip_validation)
    end

    describe 'with nil' do
      let(:value) { nil }

      it 'should raise an exception' do
        expect { described_class.coerce_integer(value) }
          .to raise_error described_class::CoercionError, error_message
      end
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }

      it 'should raise an exception' do
        expect { described_class.coerce_integer(value) }
          .to raise_error described_class::CoercionError, error_message
      end
    end

    describe 'with an empty String' do
      let(:value) { '' }

      it 'should raise an exception' do
        expect { described_class.coerce_integer(value) }
          .to raise_error described_class::CoercionError, error_message
      end

      describe 'with skip_validation: true' do
        it 'should return nil' do
          expect(described_class.coerce_integer(value, skip_validation: true))
            .to be 0
        end
      end
    end

    describe 'with an invalid String' do
      let(:value) { 'Greetings, programs!' }

      it 'should raise an exception' do
        expect { described_class.coerce_integer(value) }
          .to raise_error described_class::CoercionError, error_message
      end

      describe 'with skip_validation: true' do
        it 'should return nil' do
          expect(described_class.coerce_integer(value, skip_validation: true))
            .to be 0
        end
      end
    end

    const_get(:DECIMAL_VALUES).each do |decimal_value|
      describe "with value: '#{decimal_value}'" do
        let(:value) { decimal_value }

        it 'should raise an exception' do
          expect { described_class.coerce_integer(value) }
            .to raise_error described_class::CoercionError, error_message
        end

        describe 'with skip_validation: true' do
          let(:expected) { value.tr('_,', '').to_i }

          it 'should return nil' do
            expect(described_class.coerce_integer(value, skip_validation: true))
              .to be == expected
          end
        end
      end
    end

    const_get(:INTEGER_VALUES).each do |integer_value|
      describe "with value: '#{integer_value}'" do
        let(:value)    { integer_value }
        let(:expected) { value.tr('_,', '').to_i }

        it { expect(described_class.coerce_integer(value)).to be == expected }
      end
    end
  end

  describe '.coerce_integer?' do
    it 'should define the class predicate' do
      expect(described_class).to respond_to(:coerce_integer?).with(1).argument
    end

    describe 'with nil' do
      it { expect(described_class.coerce_integer?(nil)).to be false }
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }

      it { expect(described_class.coerce_integer?(value)).to be false }
    end

    describe 'with an empty String' do
      let(:value) { '' }

      it { expect(described_class.coerce_integer?(value)).to be false }
    end

    describe 'with an invalid String' do
      let(:value) { 'Greetings, programs!' }

      it { expect(described_class.coerce_integer?(value)).to be false }
    end

    const_get(:DECIMAL_VALUES).each do |decimal_value|
      describe "with value: '#{decimal_value}'" do
        let(:value) { decimal_value }

        it { expect(described_class.coerce_integer?(value)).to be false }
      end
    end

    const_get(:INTEGER_VALUES).each do |integer_value|
      describe "with value: '#{integer_value}'" do
        let(:value) { integer_value }

        it { expect(described_class.coerce_integer?(value)).to be true }
      end
    end
  end

  describe '.coerce_nil' do
    let(:error_message) do
      "unable to coerce #{value.inspect} to nil"
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:coerce_nil)
        .with(1).argument
        .and_keywords(:skip_validation)
    end

    describe 'with nil' do
      it { expect(described_class.coerce_nil(nil)).to be nil }
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }

      it 'should raise an exception' do
        expect { described_class.coerce_nil(value) }
          .to raise_error described_class::CoercionError, error_message
      end
    end

    describe 'with an empty String' do
      let(:value) { '' }

      it { expect(described_class.coerce_nil(value)).to be nil }
    end

    describe 'with an invalid String' do
      let(:value) { 'Greetings, programs!' }

      it 'should raise an exception' do
        expect { described_class.coerce_nil(value) }
          .to raise_error described_class::CoercionError, error_message
      end

      describe 'with skip_validation: true' do
        it 'should return nil' do
          expect(described_class.coerce_nil(value, skip_validation: true))
            .to be nil
        end
      end
    end

    const_get(:NULLISH_VALUES).each do |nullish_value|
      describe "with value: '#{nullish_value}'" do
        let(:value) { nullish_value }

        it { expect(described_class.coerce_nil(value)).to be nil }
      end

      next if nullish_value.empty?

      describe "with value: '#{nullish_value.upcase}'" do
        let(:value) { nullish_value.upcase }

        it { expect(described_class.coerce_nil(value)).to be nil }
      end
    end
  end

  describe '.coerce_nil?' do
    it 'should define the class predicate' do
      expect(described_class).to respond_to(:coerce_nil?).with(1).argument
    end

    describe 'with nil' do
      it { expect(described_class.coerce_nil?(nil)).to be true }
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }

      it { expect(described_class.coerce_nil?(value)).to be false }
    end

    describe 'with an empty String' do
      let(:value) { '' }

      it { expect(described_class.coerce_nil?(value)).to be true }
    end

    describe 'with an invalid String' do
      let(:value) { 'Greetings, programs!' }

      it { expect(described_class.coerce_nil?(value)).to be false }
    end

    const_get(:NULLISH_VALUES).each do |nullish_value|
      describe "with value: '#{nullish_value}'" do
        let(:value) { nullish_value }

        it { expect(described_class.coerce_nil?(value)).to be true }
      end

      next if nullish_value.empty?

      describe "with value: '#{nullish_value.upcase}'" do
        let(:value) { nullish_value.upcase }

        it { expect(described_class.coerce_nil?(value)).to be true }
      end
    end
  end
end
