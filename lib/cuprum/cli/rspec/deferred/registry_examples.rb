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
          'spec:example'        => Spec::ExampleCommand,
          'spec:other'          => Spec::OtherCommand,
          'spec:scoped:command' => Spec::Scoped::Command
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
          subject.register(command, name:)
        end
      end
    end

    deferred_examples 'should implement the Registry interface' do
      describe '#[]' do
        it { expect(subject).to respond_to(:[]).with(1).argument }

        describe 'with nil' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'name')
          end

          it 'should raise an exception' do
            expect { subject[nil] }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) do
            tools.assertions.error_message_for('name', as: 'name')
          end

          it 'should raise an exception' do
            expect { subject[Object.new.freeze] }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty String' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'name')
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
        let(:command) { Spec::CustomCommand }

        example_class 'Spec::CustomCommand', Cuprum::Cli::Command do |klass|
          klass.description 'A custom command.'
        end

        it 'should define the method' do
          expect(subject)
            .to respond_to(:register)
            .with(1).argument
            .and_keywords(:arguments, :options, :name)
        end

        describe 'with arguments: value' do
          let(:arguments)  { %w[ichi ni san] }
          let(:registered) { registry.commands[command.full_name] }

          it { expect(subject.register(command)).to be registry }

          it 'should register the command' do
            expect { subject.register(command, arguments:) }
              .to change(registry, :commands)
              .to have_key(command.full_name)
          end

          it 'should configure the command', :aggregate_failures do
            subject.register(command, arguments:)

            expect(registered).to be_a(Class).and(be < command)
            expect(registered.argument_values).to be == arguments
            expect(registered.option_values).to be == {}
          end
        end

        describe 'with options: value' do
          let(:options)    { { option: 'value', other: 'other' } }
          let(:registered) { registry.commands[command.full_name] }

          it { expect(subject.register(command)).to be registry }

          it 'should register the command' do
            expect { subject.register(command, options:) }
              .to change(registry, :commands)
              .to have_key(command.full_name)
          end

          it 'should configure the command', :aggregate_failures do
            subject.register(command, options:)

            expect(registered).to be_a(Class).and(be < command)
            expect(registered.argument_values).to be == []
            expect(registered.option_values).to be == options
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

        describe 'with name: an Object' do
          let(:error_message) do
            tools.assertions.error_message_for('name', as: 'name')
          end

          it 'should raise an exception' do
            expect { subject.register(command, name: Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with name: an empty String' do
          let(:error_message) do
            tools.assertions.error_message_for('presence', as: 'name')
          end

          it 'should raise an exception' do
            expect { subject.register(command, name: '') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with name: an invalid String' do
          let(:error_message) do
            'name does not match format category:sub_category:do_something'
          end

          it 'should raise an exception' do
            expect { subject.register(command, name: 'UPPER_CASE') }
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
            tools.assertions.error_message_for('presence', as: 'name')
          end

          it 'should raise an exception' do
            expect { subject.register(command) }
              .to raise_error ArgumentError, error_message
          end

          describe 'with name: value' do
            let(:name) { 'custom:scoped:command' }

            it 'should register the command', :aggregate_failures do
              expect { subject.register(command, name:) }
                .to change(registry, :commands)
                .to have_key(name)

              expect(registry.commands[name]).to be command
            end

            context 'when the registry already defines the command' do
              let(:other_command) do
                Class.new(Cuprum::Cli::Command) do
                  description 'Another anonymous command.'
                end
              end
              let(:error_message) do
                "command already registered as #{name} - " \
                  "#{other_command.inspect}"
              end

              before(:example) do
                subject.register(other_command, name:)
              end

              it 'should raise an exception' do
                expect { subject.register(command, name:) }
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
                "#{other_command.inspect}"
            end

            before(:example) do
              subject.register(other_command, name: command.full_name)
            end

            it 'should raise an exception' do
              expect { subject.register(command) }
                .to raise_error NameError, error_message
            end
          end

          describe 'with name: value' do
            let(:name) { 'custom:scoped:command' }

            it 'should register the command', :aggregate_failures do
              expect { subject.register(command, name:) }
                .to change(registry, :commands)
                .to have_key(name)

              expect(registry.commands[name]).to be command
            end

            context 'when the registry already defines the command' do
              let(:other_command) do
                Class.new(Cuprum::Cli::Command) do
                  description 'Another anonymous command.'
                end
              end
              let(:error_message) do
                "command already registered as #{name} - " \
                  "#{other_command.inspect}"
              end

              before(:example) do
                subject.register(other_command, name:)
              end

              it 'should raise an exception' do
                expect { subject.register(command, name:) }
                  .to raise_error NameError, error_message
              end
            end
          end
        end
      end
    end
  end
end
