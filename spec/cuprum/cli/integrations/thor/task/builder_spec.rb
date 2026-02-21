# frozen_string_literal: true

require 'cuprum/cli/command'
require 'cuprum/cli/integrations/thor/task'

RSpec.describe Cuprum::Cli::Integrations::Thor::Task::Builder,
  integration: :thor \
do
  subject(:builder) { described_class.new(command_class) }

  let(:description) do
    'No one is quite sure what this does.'
  end
  let(:full_name) { 'spec:custom' }
  let(:command_class) do
    Class.new(Cuprum::Cli::Command).tap do |klass|
      klass.description(description)

      klass.full_name(full_name)
    end
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(1).argument }

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('class', as: 'command_class')
      end

      it 'should raise an exception' do
        expect { described_class.new(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('class', as: 'command_class')
      end

      it 'should raise an exception' do
        expect { described_class.new(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an invalid Class' do
      let(:error_message) do
        tools.assertions.error_message_for(
          'inherit_from',
          as:       'command_class',
          expected: Cuprum::Cli::Command
        )
      end

      it 'should raise an exception' do
        expect { described_class.new(Class.new) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a command Class without a description' do
      let(:error_message) do
        'command_class does not have a description'
      end
      let(:command_class) do
        Class.new(Cuprum::Cli::Command) do
          full_name 'spec:custom'
        end
      end

      it 'should raise an exception' do
        expect { described_class.new(command_class) }
          .to raise_error ArgumentError, error_message
      end
    end
  end

  describe '#build' do
    let(:task_class)   { builder.build }
    let(:task)         { task_class.new }
    let(:thor_command) { task_class.commands[command_class.short_name] }

    it 'should define the method' do
      expect(builder)
        .to respond_to(:build)
        .with(0).arguments
        .and_keywords(:full_name)
    end

    it { expect(task_class).to be_a(Class) }

    it { expect(task_class).to be < Cuprum::Cli::Integrations::Thor::Task }

    it { expect(task_class.arguments).to be == [] }

    it { expect(task.command_class).to be command_class }

    it { expect(task_class.namespace).to be == command_class.namespace }

    it 'should define the task method' do
      expect(task)
        .to have_aliased_method(:call_command)
        .as(command_class.short_name)
    end

    it { expect(thor_command.description).to be == command_class.description }

    it { expect(thor_command.long_description).to be nil }

    it { expect(thor_command.options).to be == {} }

    it { expect(thor_command.usage).to be == command_class.short_name }

    context 'when the command class does not have a namespace' do
      let(:full_name) { 'do_something' }

      it { expect(task_class.namespace).to be == 'default' }

      it { expect(thor_command.usage).to be == command_class.short_name }
    end

    context 'when the command class has a full description' do
      let(:value) do
        <<~DESC
          No one is quite sure what this does.

          ...but it sure looks cool!
        DESC
      end

      before(:example) { command_class.full_description(value) }

      it { expect(thor_command.long_description).to be == value }
    end

    context 'when the command class defines arguments' do
      let(:expected_arguments) do
        [
          {
            banner:      'COLOR',
            description: nil,
            name:        'color',
            required:    true,
            type:        :numeric
          },
          {
            banner:      '<circle, square, triangle>',
            description: nil,
            name:        'shape',
            required:    false,
            type:        :string
          }
        ]
      end
      let(:expected_usage) do
        "#{command_class.short_name} COLOR <circle, square, triangle>"
      end

      before(:example) do
        command_class.argument :color, required: true, type: :integer
        command_class.argument :shape,
          parameter_name: '<circle, square, triangle>'
      end

      it { expect(thor_command.usage).to be == expected_usage }

      it 'should define the arguments', :aggregate_failures do
        expect(task_class.arguments.size).to be == expected_arguments.size

        task_class.arguments.zip(expected_arguments).each \
        do |argument, expected|
          expect(argument).to have_attributes(**expected)
        end
      end
    end

    context 'when the command class defines a variadic argument' do
      let(:expected_arguments) do
        [
          {
            banner:      'COLOR',
            description: nil,
            name:        'color',
            required:    true,
            type:        :numeric
          },
          {
            banner:      'SHAPE',
            description: nil,
            name:        'shape',
            required:    false,
            type:        :string
          },
          {
            banner:      'SIZES',
            description: nil,
            name:        'sizes',
            required:    false,
            type:        :array
          },
          {
            banner:      'TRANSPARENCY',
            description: nil,
            name:        'transparency',
            required:    false,
            type:        :string
          }
        ]
      end
      let(:expected_usage) do
        "#{command_class.short_name} COLOR SHAPE ...SIZES TRANSPARENCY"
      end

      before(:example) do
        command_class.argument :color, required: true, type: :integer
        command_class.argument :shape
        command_class.argument :sizes, variadic: true
        command_class.argument :transparency
      end

      it { expect(thor_command.usage).to be == expected_usage }

      it 'should define the arguments', :aggregate_failures do
        expect(task_class.arguments.size).to be == expected_arguments.size

        task_class.arguments.zip(expected_arguments).each \
        do |argument, expected|
          expect(argument).to have_attributes(**expected)
        end
      end
    end

    context 'when the command class defines options' do
      let(:expected_options) do
        {
          color:       {
            aliases:     [],
            banner:      'COLOR',
            description: nil,
            name:        'color',
            required:    false,
            type:        :numeric
          },
          shape:       {
            aliases:     [],
            banner:      '<circle, square, triangle>',
            description: nil,
            name:        'shape',
            required:    true,
            type:        :string
          },
          transparent: {
            aliases:     %w[-t],
            banner:      'TRANSPARENT',
            description: nil,
            name:        'transparent',
            required:    false,
            type:        :boolean
          }
        }
      end

      before(:example) do
        command_class.option :color, type: :integer
        command_class.option :shape,
          required:       true,
          parameter_name: '<circle, square, triangle>'
        command_class.option :transparent, type: :boolean, aliases: 't'
      end

      it 'should define the options', :aggregate_failures do
        expect(thor_command.options.keys).to be == expected_options.keys

        thor_command.options.each do |name, option|
          expect(option).to have_attributes(**expected_options[name])
        end
      end
    end

    context 'when the command class is an anonymous class' do
      let(:command_class) do
        Class.new(Cuprum::Cli::Command).tap do |klass|
          klass.description(description)
        end
      end
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'full_name')
      end

      it 'should raise an exception' do
        expect { builder.build }
          .to raise_error ArgumentError, error_message
      end

      describe 'with full_name: unscoped value' do
        let(:custom_name) { 'do_something' }
        let(:task_class)  { builder.build(full_name: custom_name) }

        it { expect(task_class.namespace).to be == 'default' }

        it 'should define the task method' do
          expect(task)
            .to have_aliased_method(:call_command)
            .as(:do_something)
        end
      end

      describe 'with full_name: scoped value' do
        let(:custom_name) { 'category:sub_category:do_something' }
        let(:task_class)  { builder.build(full_name: custom_name) }

        it { expect(task_class.namespace).to be == 'category:sub_category' }

        it 'should define the task method' do
          expect(task)
            .to have_aliased_method(:call_command)
            .as(:do_something)
        end
      end
    end

    describe 'with full_name: nil' do
      let(:task_class) { builder.build(full_name: nil) }

      it { expect(task_class.namespace).to be == command_class.namespace }

      it 'should define the task method' do
        expect(task)
          .to have_aliased_method(:call_command)
          .as(command_class.short_name)
      end
    end

    describe 'with full_name: an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('name', as: 'full_name')
      end

      it 'should raise an exception' do
        expect { builder.build(full_name: Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with full_name: unscoped value' do
      let(:custom_name) { 'do_something' }
      let(:task_class)  { builder.build(full_name: custom_name) }

      it { expect(task_class.namespace).to be == 'default' }

      it 'should define the task method' do
        expect(task)
          .to have_aliased_method(:call_command)
          .as(:do_something)
      end
    end

    describe 'with full_name: scoped value' do
      let(:custom_name) { 'category:sub_category:do_something' }
      let(:task_class)  { builder.build(full_name: custom_name) }

      it { expect(task_class.namespace).to be == 'category:sub_category' }

      it 'should define the task method' do
        expect(task)
          .to have_aliased_method(:call_command)
          .as(:do_something)
      end
    end
  end

  describe '#command_class' do
    include_examples 'should define reader', :command_class
  end
end
