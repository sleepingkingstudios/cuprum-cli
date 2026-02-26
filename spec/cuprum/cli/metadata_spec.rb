# frozen_string_literal: true

require 'cuprum/cli/metadata'
require 'cuprum/cli/rspec/deferred/metadata_examples'

RSpec.describe Cuprum::Cli::Metadata do
  include Cuprum::Cli::RSpec::Deferred::MetadataExamples

  let(:described_class) { Spec::CustomCommand }
  let(:concern)         { Cuprum::Cli::Metadata } # rubocop:disable RSpec/DescribedClass

  deferred_context 'when the command has a parent command' do
    let(:parent_class)    { Spec::CustomCommand }
    let(:described_class) { Spec::SubclassCommand }

    example_class 'Spec::SubclassCommand', 'Spec::CustomCommand'
  end

  deferred_context 'when the command is an anonymous class' do
    let(:parent_class) do
      defined?(super()) ? super() : Object
    end
    let(:described_class) do
      Class.new(parent_class) do
        include Cuprum::Cli::Metadata

        def self.name
          Class.instance_method(:name).bind(self).call
        end
      end
    end
  end

  example_class 'Spec::CustomCommand' do |klass|
    klass.include concern
  end

  describe '::FULL_NAME_FORMAT' do
    let(:format) { described_class::FULL_NAME_FORMAT }

    include_examples 'should define constant',
      :FULL_NAME_FORMAT,
      -> { an_instance_of(Regexp) }

    describe 'with an empty String' do
      it { expect(format.match?('')).to be false }
    end

    describe 'with an upper-case String' do
      it { expect(format.match?('UPPER_CASE')).to be false }
    end

    describe 'with a string containing a number' do
      it { expect(format.match?('lower1number')).to be false }
    end

    describe 'with a string containing consecutive colons' do
      it { expect(format.match?('double::colons')).to be false }
    end

    describe 'with a string separated by slashes' do
      it { expect(format.match?('slash/separator')).to be false }
    end

    describe 'with a valid unscoped string' do
      it { expect(format.match?('lower_case')).to be true }
    end

    describe 'with a valid scoped string' do
      it { expect(format.match?('colon:separated:string')).to be true }
    end
  end

  include_deferred 'should implement the Metadata interface'

  include_deferred 'should define metadata for the command'
end
