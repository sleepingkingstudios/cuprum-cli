# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'cuprum/cli/rspec/deferred'

module Cuprum::Cli::RSpec::Deferred
  # Deferred examples for testing command options/
  module OptionsExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_examples 'should define option' do |option_name, **option_options|
      expect_method =
        option_options
        .fetch(:define_method, option_options[:type] != :boolean)
      expect_predicate =
        option_options
        .fetch(:define_predicate, option_options[:type] == :boolean)

      let(:configured_aliases) do
        value = option_options.fetch(:aliases, [])
        value = value.instance_exec(&value) if value.is_a?(Proc)

        value
          .then { |ary| Array(ary) }
          .map(&:to_s)
      end
      let(:configured_default) do
        value = option_options[:default]

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:configured_description) do
        value = option_options[:description]

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:configured_required) do
        value = option_options[:required] ? true : false

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:configured_type) do
        value = option_options.fetch(:type, :string)

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:configured_options) do
        value = option_options.fetch(:options) do
          defined?(options) ? options : {}
        end

        value.is_a?(Proc) ? instance_exec(&value) : value
      end
      let(:defined_option) { described_class.options[option_name.to_sym] }

      it { expect(described_class.options).to have_key(option_name.to_sym) }

      describe '#:option_name' do
        if expect_method
          let(:reader_name) { option_name }
          let(:expected)    { configured_options[option_name] }

          it { expect(subject).to respond_to(reader_name).with(0).arguments }

          it { expect(subject.public_send(reader_name)).to be == expected }
        else
          it { expect(subject).not_to respond_to(option_name) }
        end
      end

      describe '#:option_name?' do
        if expect_predicate
          let(:predicate_name) { "#{option_name}?" }
          let(:expected) do
            value = configured_options[option_name]

            !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
          end

          it { expect(subject).to respond_to(predicate_name).with(0).arguments }

          it { expect(subject.public_send(predicate_name)).to be == expected }
        else
          it { expect(subject).not_to respond_to(:"#{option_name}?") }
        end
      end

      describe '#aliases' do
        it { expect(defined_option.aliases).to be == configured_aliases }
      end

      describe '#default' do
        it { expect(defined_option.default).to be == configured_default }
      end

      describe '#description' do
        it 'should return the option description' do
          expect(defined_option.description).to be == configured_description
        end
      end

      describe '#required?' do
        it { expect(defined_option.required?).to be configured_required }
      end

      describe '#type' do
        it { expect(defined_option.type).to be configured_type }
      end
    end
  end
end
