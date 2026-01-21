# frozen_string_literal: true

require 'cuprum/cli/options/class_methods'

RSpec.describe Cuprum::Cli::Options::ClassMethods do
  deferred_context 'when the command has a parent command' do
    let(:described_class) { Spec::SubclassCommand }

    example_class 'Spec::SubclassCommand', 'Spec::Command'
  end

  deferred_context 'when the command has many options' do
    before(:example) do
      described_class.option :color, type: :integer
      described_class.option :shape, required: true
    end
  end

  deferred_context 'when the parent command has many options' do
    before(:example) do
      Spec::Command.option :size
      Spec::Command.option :transparent, type: :boolean
    end
  end

  let(:described_class) { Spec::Command }

  example_class 'Spec::Command' do |klass|
    klass.extend Cuprum::Cli::Options::ClassMethods # rubocop:disable RSpec/DescribedClass
  end

  describe '.option' do
    deferred_examples 'should define the option' do
      context 'when the option is defined' do
        let(:expected_options) do
          {
            aliases:  [],
            name:     name.to_sym,
            required: false,
            type:     :string
          }.merge(options)
        end

        before(:example) { described_class.option(name, **options) }

        it { expect(described_class.options).to have_key(name.to_sym) }

        it 'should configure the option', :aggregate_failures do
          option = described_class.options[name.to_sym]

          expected_options.each do |key, expected|
            expect(option.public_send(key)).to be == expected
          end
        end
      end
    end

    let(:name)    { :format }
    let(:options) { {} }
    let(:expected_keywords) do
      %i[
        aliases
        default
        description
        name
        required
        type
      ]
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:option)
        .with(1).argument
        .and_keywords(*expected_keywords)
    end

    describe 'with name: a String' do
      let(:name) { 'format' }

      it { expect(described_class.option(name)).to be name.to_sym }

      include_deferred 'should define the option'
    end

    describe 'with name: a Symbol' do
      let(:name) { :format }

      it { expect(described_class.option(name)).to be name }

      include_deferred 'should define the option'
    end
  end

  describe '.options' do
    it { expect(described_class).to respond_to(:options).with(0).arguments }

    it { expect(described_class.options).to be == {} }

    wrap_deferred 'when the command has many options' do
      let(:expected_keys) { %i[color shape] }

      it 'should define the expected options' do
        expect(described_class.options.keys).to match_array(expected_keys)
      end

      it { expect(described_class.options[:color].type).to be :integer }
    end

    wrap_deferred 'when the command has a parent command' do
      it { expect(described_class.options).to be == {} }

      wrap_deferred 'when the command has many options' do
        let(:expected_keys) { %i[color shape] }

        it 'should define the expected options' do
          expect(described_class.options.keys).to match_array(expected_keys)
        end

        it { expect(described_class.options[:color].type).to be :integer }
      end

      wrap_deferred 'when the parent command has many options' do
        let(:expected_keys) { %i[size transparent] }

        it 'should define the expected options' do
          expect(described_class.options.keys).to match_array(expected_keys)
        end

        it { expect(described_class.options[:transparent].type).to be :boolean }
      end

      context 'when the command and parent command have many options' do
        let(:expected_keys) { %i[color shape size transparent] }

        include_deferred 'when the command has many options'
        include_deferred 'when the parent command has many options'

        it 'should define the expected options' do
          expect(described_class.options.keys).to match_array(expected_keys)
        end
      end
    end
  end
end
