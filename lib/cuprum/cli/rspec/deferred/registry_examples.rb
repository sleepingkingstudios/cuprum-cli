# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'cuprum/cli/rspec/deferred'

module Cuprum::Cli::RSpec::Deferred
  # Deferred examples for testing command registries.
  module RegistryExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_context 'when the registry has many commands' do
      let(:commands) do
        {
          'spec:example' => Spec::ExampleCommand,
          'spec:other'   => Spec::OtherCommand,
          'spec:scoped'  => Spec::Scoped::Command
        }
      end

      example_class 'Spec::ExampleCommand',  Cuprum::Cli::Command
      example_class 'Spec::OtherCommand',    Cuprum::Cli::Command
      example_class 'Spec::Scoped::Command', Cuprum::Cli::Command

      before(:example) do
        Spec::ExampleCommand.description  'An example command.'
        Spec::OtherCommand.description    'Another command.'
        Spec::Scoped::Command.description 'A scoped command.'

        commands.each do |name, command|
          command.full_name(name)

          subject.register(command)
        end
      end
    end

    deferred_examples 'should implement the Registry interface' do
      describe '#[]' do
        it { expect(subject).to respond_to(:[]).with(1).argument }

        describe 'with nil' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'full_name')
          end

          it 'should raise an exception' do
            expect { subject[nil] }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) do
            tools.assertions.error_message_for('name', as: 'full_name')
          end

          it 'should raise an exception' do
            expect { subject[Object.new.freeze] }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty String' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'full_name')
          end

          it 'should raise an exception' do
            expect { subject[''] }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an invalid String' do
          it { expect(subject['invalid:command']).to be nil }
        end

        wrap_deferred 'when the registry has many commands' do
          describe 'with an invalid String' do
            it { expect(subject['invalid:command']).to be nil }
          end

          describe 'with a valid String' do
            let(:name)     { 'spec:example' }
            let(:expected) { commands[name] }

            it { expect(subject[name]).to be expected }
          end
        end
      end

      describe '#commands' do
        include_examples 'should define reader', :commands, {}

        it { expect(subject.commands).to be_frozen }

        wrap_deferred 'when the registry has many commands' do
          it { expect(subject.commands).to eq(commands) }
        end
      end

      describe '#register' do
        deferred_examples 'should register command' do |command_class, **config|
          context 'when the command is registered' do
            let(:expected_command) do
              expected = command_class
              expected = instance_exec(&expected)   if expected.is_a?(Proc)
              expected = Object.const_get(expected) if expected.is_a?(String)

              expected
            end
            let(:expected_arguments) do
              config.fetch(:arguments, [])
            end
            let(:expected_description) do
              config
                .fetch(:description, expected_command.description)
                .then do |value|
                  value.is_a?(Proc) ? instance_exec(&value) : value
                end
            end
            let(:expected_full_description) do
              config
                .fetch(:full_description) do
                  config.fetch(:description, expected_command.full_description)
                end # rubocop:disable Style/MultilineBlockChain
                .then do |value|
                  value.is_a?(Proc) ? instance_exec(&value) : value
                end
            end
            let(:expected_full_name) do
              config.fetch(:full_name, expected_command.full_name)
            end
            let(:expected_options) do
              config.fetch(:options, {})
            end
            let(:registered) do
              registry.commands[expected_full_name]
            end

            before(:example) { register_commands }

            it { expect(registered).to be_a(Class).and(be <= expected_command) }

            it 'should configure the command arguments' do
              expect(registered.argument_values).to eq(expected_arguments)
            end

            it 'should configure the command description' do
              expect(registered.description).to eq(expected_description)
            end

            it 'should configure the command full description' do
              expect(registered.full_description)
                .to eq(expected_full_description)
            end

            it 'should configure the command full name' do
              expect(registered.full_name).to eq(expected_full_name)
            end

            it 'should configure the command options' do
              expect(registered.option_values).to eq(expected_options)
            end
          end
        end

        let(:expected_keywords) do
          %i[
            arguments
            description
            full_description
            full_name
            options
          ]
        end
        let(:commands) { [Spec::CustomCommand] }
        let(:config)   { {} }
        let(:block)    { nil }

        define_method :register_commands do
          registry.register(*commands, **config, &block)
        end

        example_class 'Spec::CustomCommand', Cuprum::Cli::Command do |klass|
          klass.description 'A custom command.'
        end

        it 'should define the method' do
          expect(subject)
            .to respond_to(:register)
            .with(1).argument
            .and_unlimited_arguments
            .and_keywords(*expected_keywords)
            .and_a_block
        end

        it 'should alias the method as #add' do
          expect(subject)
            .to have_aliased_method(:register)
            .as(:add)
        end

        describe 'with no commands' do
          let(:commands) { [] }
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'commands')
          end

          it 'should raise an exception' do
            expect { register_commands }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with command: nil' do
          let(:error_message) do
            tools.assertions.error_message_for('class', as: 'command')
          end

          it 'should raise an exception' do
            expect { subject.register(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with command: an Object' do
          let(:error_message) do
            tools.assertions.error_message_for('class', as: 'command')
          end

          it 'should raise an exception' do
            expect { subject.register(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with command: a non-Command class' do
          let(:error_message) do
            tools.assertions.error_message_for(
              'inherit_from',
              as:       'command',
              expected: Cuprum::Cli::Command
            )
          end

          it 'should raise an exception' do
            expect { subject.register(Class.new) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with full_name: an Object' do
          let(:config) { super().merge(full_name: Object.new.freeze) }
          let(:error_message) do
            tools.assertions.error_message_for('name', as: 'full_name')
          end

          it 'should raise an exception' do
            expect { register_commands }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with full_name: an empty String' do
          let(:config) { super().merge(full_name: '') }
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'full_name')
          end

          it 'should raise an exception' do
            expect { register_commands }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with full_name: an invalid String' do
          let(:config) { super().merge(full_name: 'UPPER_CASE') }
          let(:error_message) do
            'full_name does not match format category:sub_category:do_something'
          end

          it 'should raise an exception' do
            expect { register_commands }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with command: an anonymous command class' do
          let(:commands) do
            [
              Class.new(Cuprum::Cli::Command) do
                description 'An anonymous command.'
              end
            ]
          end
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'full_name')
          end

          it 'should raise an exception' do
            expect { register_commands }
              .to raise_error ArgumentError, error_message
          end

          describe 'with full_name: value' do
            let(:full_name) { 'custom:scoped:command' }
            let(:config)    { super().merge(full_name:) }

            it { expect(register_commands).to be registry }

            include_deferred 'should register command',
              -> { commands.first },
              full_name: 'custom:scoped:command'

            context 'when the registry already defines the command' do
              let(:other_command) do
                Class.new(Cuprum::Cli::Command) do
                  description 'Another anonymous command.'
                end
              end
              let(:error_message) do
                "command already registered as #{full_name} - " \
                  'Cuprum::Cli::Command'
              end

              before(:example) do
                subject.register(other_command, full_name:)
              end

              it 'should raise an exception' do
                expect { register_commands }
                  .to raise_error NameError, error_message
              end
            end
          end
        end

        describe 'with command: a command class' do
          let(:commands) { [Spec::CustomCommand] }

          it { expect(register_commands).to be registry }

          include_deferred 'should register command', 'Spec::CustomCommand'

          context 'when the registry already defines the command' do
            let(:other_command) do
              Class.new(Cuprum::Cli::Command) do
                description 'Another anonymous command.'
              end
            end
            let(:error_message) do
              "command already registered as #{commands.first.full_name} - " \
                'Cuprum::Cli::Command'
            end

            before(:example) do
              subject.register(other_command, full_name: 'spec:custom')
            end

            it 'should raise an exception' do
              expect { register_commands }
                .to raise_error NameError, error_message
            end
          end

          describe 'with arguments: value' do
            let(:arguments) { %w[ichi ni san] }
            let(:config)    { super().merge(arguments:) }

            it { expect(register_commands).to be registry }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              arguments: %w[ichi ni san]
          end

          describe 'with description: value' do
            let(:description) { 'No one is quite sure what this does.' }
            let(:config)      { super().merge(description:) }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              description: -> { description }
          end

          describe 'with full_description: value' do
            let(:full_description) do
              <<~DESC
                No one is quite sure what this does.

                ...but it sure looks cool!
              DESC
            end
            let(:config) { super().merge(full_description:) }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_description: -> { full_description }
          end

          describe 'with full_name: value' do
            let(:full_name) { 'custom:scoped:command' }
            let(:config)    { super().merge(full_name:) }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'custom:scoped:command'

            context 'when the registry already defines the command' do
              let(:other_command) do
                Class.new(Cuprum::Cli::Command) do
                  description 'Another anonymous command.'
                end
              end
              let(:error_message) do
                "command already registered as #{full_name} - " \
                  'Cuprum::Cli::Command'
              end

              before(:example) do
                subject.register(other_command, full_name:)
              end

              it 'should raise an exception' do
                expect { register_commands }
                  .to raise_error NameError, error_message
              end
            end
          end

          describe 'with options: value' do
            let(:options) { { option: 'value', other: 'other' } }
            let(:config)  { super().merge(options:) }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              options: { option: 'value', other: 'other' }
          end

          describe 'with multiple config options' do
            let(:arguments)   { %w[ichi ni san] }
            let(:description) { 'No one is quite sure what this does.' }
            let(:options)     { { option: 'value', other: 'other' } }
            let(:config) do
              super().merge(arguments:, description:, options:)
            end

            include_deferred 'should register command',
              'Spec::CustomCommand',
              arguments:   %w[ichi ni san],
              description: -> { description },
              options:     { option: 'value', other: 'other' }
          end

          describe 'with a block that configures the command' do
            let(:block) do
              lambda do |command|
                command.with_full_name 'spec:example_command'
              end
            end

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example_command'
          end

          describe 'with a block that filters the command' do
            let(:block) do
              ->(_command) {}
            end

            it { expect(register_commands).to be registry }

            it 'should not register a command' do
              expect { register_commands }.not_to change(registry, :commands)
            end
          end
        end

        describe 'with multiple command classes' do
          let(:commands) do
            [
              Class
                .new(Spec::CustomCommand)
                .with_full_name('spec:example:command_one'),
              Class
                .new(Spec::CustomCommand)
                .with_full_name('spec:example:command_two'),
              Class
                .new(Spec::CustomCommand)
                .with_full_name('spec:example:command_three')
            ]
          end

          it { expect(register_commands).to be registry }

          include_deferred 'should register command',
            'Spec::CustomCommand',
            full_name: 'spec:example:command_one'

          include_deferred 'should register command',
            'Spec::CustomCommand',
            full_name: 'spec:example:command_two'

          include_deferred 'should register command',
            'Spec::CustomCommand',
            full_name: 'spec:example:command_three'

          describe 'with configuration options' do
            let(:config) { super().merge(options: { key: 'value' }) }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example:command_one',
              options:   { key: 'value' }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example:command_two',
              options:   { key: 'value' }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example:command_three',
              options:   { key: 'value' }
          end

          describe 'with a block that configures the commands' do
            let(:block) do
              lambda do |command|
                name = command.full_name.sub('example', 'custom')

                command.with_full_name(name)
              end
            end

            it { expect(register_commands).to be registry }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:custom:command_one'

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:custom:command_two'

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:custom:command_three'
          end

          describe 'with a block that filters the commands' do
            let(:block) do
              lambda do |command|
                next if command.full_name.include?('two')

                command
              end
            end

            it { expect(register_commands).to be registry }

            it 'should not register filtered commands' do
              register_commands

              expect(registry.commands)
                .not_to have_key('spec:example:command_two')
            end

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example:command_one'

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example:command_three'
          end
        end

        describe 'with an Array of command classes' do
          let(:commands) do
            [
              Class
                .new(Spec::CustomCommand)
                .with_full_name('spec:example:command_one'),
              [
                Class
                  .new(Spec::CustomCommand)
                  .with_full_name('spec:example:command_two'),
                Class
                  .new(Spec::CustomCommand)
                  .with_full_name('spec:example:command_three')
              ]
            ]
          end

          it { expect(register_commands).to be registry }

          include_deferred 'should register command',
            'Spec::CustomCommand',
            full_name: 'spec:example:command_one'

          include_deferred 'should register command',
            'Spec::CustomCommand',
            full_name: 'spec:example:command_two'

          include_deferred 'should register command',
            'Spec::CustomCommand',
            full_name: 'spec:example:command_three'

          describe 'with configuration options' do
            let(:config) { super().merge(options: { key: 'value' }) }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example:command_one',
              options:   { key: 'value' }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example:command_two',
              options:   { key: 'value' }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example:command_three',
              options:   { key: 'value' }
          end

          describe 'with a block that configures the commands' do
            let(:block) do
              lambda do |command|
                name = command.full_name.sub('example', 'custom')

                command.with_full_name(name)
              end
            end

            it { expect(register_commands).to be registry }

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:custom:command_one'

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:custom:command_two'

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:custom:command_three'
          end

          describe 'with a block that filters the commands' do
            let(:block) do
              lambda do |command|
                next if command.full_name.include?('two')

                command
              end
            end

            it { expect(register_commands).to be registry }

            it 'should not register filtered commands' do
              register_commands

              expect(registry.commands)
                .not_to have_key('spec:example:command_two')
            end

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example:command_one'

            include_deferred 'should register command',
              'Spec::CustomCommand',
              full_name: 'spec:example:command_three'
          end
        end
      end
    end
  end
end
