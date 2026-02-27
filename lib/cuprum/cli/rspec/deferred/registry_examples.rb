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
          it { expect(subject.commands).to be == commands }
        end
      end

      describe '#register' do
        deferred_examples 'should configure the command' do
          context 'when the command is registered' do
            let(:expected_arguments) do
              config.fetch(:arguments, [])
            end
            let(:expected_description) do
              config.fetch(:description, command.description)
            end
            let(:expected_full_description) do
              config.fetch(:full_description) do
                config.fetch(:description, command.full_description)
              end
            end
            let(:expected_full_name) do
              config.fetch(:full_name, command.full_name)
            end
            let(:expected_options) do
              config.fetch(:options, {})
            end

            before(:example) { registry.register(command, **config) }

            it { expect(registered).to be_a(Class).and(be < command) }

            it 'should configure the command argument values' do
              expect(registered.argument_values).to be == expected_arguments
            end

            it 'should configure the command description' do
              expect(registered.description).to be == expected_description
            end

            it 'should configure the command full description' do
              expect(registered.full_description)
                .to be == expected_full_description
            end

            it 'should configure the command full name' do
              expect(registered.full_name).to be == expected_full_name
            end

            it 'should configure the command option values' do
              expect(registered.option_values).to be == expected_options
            end
          end
        end

        let(:command) { Spec::CustomCommand }
        let(:config)  { {} }
        let(:expected_keywords) do
          %i[
            arguments
            description
            full_description
            full_name
            options
          ]
        end
        let(:registered) do
          name = config.fetch(:full_name, command.full_name)

          registry.commands[name]
        end

        example_class 'Spec::CustomCommand', Cuprum::Cli::Command do |klass|
          klass.description 'A custom command.'
        end

        it 'should define the method' do
          expect(subject)
            .to respond_to(:register)
            .with(1).argument
            .and_keywords(*expected_keywords)
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
          let(:error_message) do
            tools.assertions.error_message_for('name', as: 'full_name')
          end

          it 'should raise an exception' do
            expect { subject.register(command, full_name: Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with full_name: an empty String' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'full_name')
          end

          it 'should raise an exception' do
            expect { subject.register(command, full_name: '') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with full_name: an invalid String' do
          let(:error_message) do
            'full_name does not match format category:sub_category:do_something'
          end

          it 'should raise an exception' do
            expect { subject.register(command, full_name: 'UPPER_CASE') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with command: an anonymous command class' do
          let(:command) do
            Class.new(Cuprum::Cli::Command) do
              description 'An anonymous command.'
            end
          end
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'full_name')
          end

          it 'should raise an exception' do
            expect { subject.register(command) }
              .to raise_error ArgumentError, error_message
          end

          describe 'with full_name: value' do
            let(:full_name) { 'custom:scoped:command' }
            let(:config)    { super().merge(full_name:) }

            it 'should register the command' do
              expect { subject.register(command, full_name:) }
                .to change(registry, :commands)
                .to have_key(full_name)
            end

            include_deferred 'should configure the command'

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
                expect { subject.register(command, full_name:) }
                  .to raise_error NameError, error_message
              end
            end
          end
        end

        describe 'with command: a command class' do
          it { expect(subject.register(command)).to be registry }

          it 'should register the command', :aggregate_failures do
            expect { subject.register(command) }
              .to change(registry, :commands)
              .to have_key(command.full_name)

            expect(registry.commands[command.full_name]).to be command
          end

          context 'when the registry already defines the command' do
            let(:other_command) do
              Class.new(Cuprum::Cli::Command) do
                description 'Another anonymous command.'
              end
            end
            let(:error_message) do
              "command already registered as #{command.full_name} - " \
                'Cuprum::Cli::Command'
            end

            before(:example) do
              subject.register(other_command, full_name: command.full_name)
            end

            it 'should raise an exception' do
              expect { subject.register(command) }
                .to raise_error NameError, error_message
            end
          end

          describe 'with full_name: value' do
            let(:full_name) { 'custom:scoped:command' }
            let(:config)    { super().merge(full_name:) }

            it 'should register the command' do
              expect { subject.register(command, full_name:) }
                .to change(registry, :commands)
                .to have_key(full_name)
            end

            include_deferred 'should configure the command'

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
                expect { subject.register(command, full_name:) }
                  .to raise_error NameError, error_message
              end
            end
          end
        end

        describe 'with arguments: value' do
          let(:arguments) { %w[ichi ni san] }
          let(:config)    { super().merge(arguments:) }

          it { expect(subject.register(command)).to be registry }

          it 'should register the command' do
            expect { subject.register(command, arguments:) }
              .to change(registry, :commands)
              .to have_key(command.full_name)
          end

          include_deferred 'should configure the command'
        end

        describe 'with description: value' do
          let(:description) { 'No one is quite sure what this does.' }
          let(:config)      { super().merge(description:) }

          it 'should register the command' do
            expect { subject.register(command, description:) }
              .to change(registry, :commands)
              .to have_key(command.full_name)
          end

          include_deferred 'should configure the command'
        end

        describe 'with full_description: value' do
          let(:full_description) do
            <<~DESC
              No one is quite sure what this does.

              ...but it sure looks cool!
            DESC
          end
          let(:config) { super().merge(full_description:) }

          it 'should register the command' do
            expect { subject.register(command, full_description:) }
              .to change(registry, :commands)
              .to have_key(command.full_name)
          end

          include_deferred 'should configure the command'
        end

        describe 'with options: value' do
          let(:options) { { option: 'value', other: 'other' } }
          let(:config)  { super().merge(options:) }

          it 'should register the command' do
            expect { subject.register(command, options:) }
              .to change(registry, :commands)
              .to have_key(command.full_name)
          end

          include_deferred 'should configure the command'
        end

        describe 'with multiple config options' do
          let(:arguments)   { %w[ichi ni san] }
          let(:description) { 'No one is quite sure what this does.' }
          let(:options)     { { option: 'value', other: 'other' } }
          let(:config) do
            super().merge(arguments:, description:, options:)
          end

          it 'should register the command' do
            expect { subject.register(command, **config) }
              .to change(registry, :commands)
              .to have_key(command.full_name)
          end

          include_deferred 'should configure the command'
        end
      end
    end
  end
end
