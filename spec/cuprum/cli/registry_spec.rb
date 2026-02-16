# frozen_string_literal: true

require 'cuprum/cli/registry'

RSpec.describe Cuprum::Cli::Registry do
  subject(:registry) { described_class.new }

  deferred_context 'when the registry has many commands' do
    let(:commands) do
      {
        'spec:example'        => Class.new(Cuprum::Cli::Command),
        'spec:other'          => Class.new(Cuprum::Cli::Command),
        'spec:scoped:command' => Class.new(Cuprum::Cli::Command)
      }
    end

    before(:example) do
      commands.each do |name, command|
        registry.register(command, name:)
      end
    end
  end

  describe '#[]' do
    it { expect(registry).to respond_to(:[]).with(1).argument }

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'name')
      end

      it 'should raise an exception' do
        expect { registry[nil] }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('name', as: 'name')
      end

      it 'should raise an exception' do
        expect { registry[Object.new.freeze] }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'name')
      end

      it 'should raise an exception' do
        expect { registry[''] }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an invalid String' do
      it { expect(registry['invalid:command']).to be nil }
    end

    wrap_deferred 'when the registry has many commands' do
      describe 'with an invalid String' do
        it { expect(registry['invalid:command']).to be nil }
      end

      describe 'with a valid String' do
        let(:name)     { 'spec:example' }
        let(:expected) { commands[name] }

        it { expect(registry[name]).to be expected }
      end
    end
  end

  describe '#commands' do
    include_examples 'should define reader', :commands, {}

    it { expect(registry.commands).to be_frozen }

    wrap_deferred 'when the registry has many commands' do
      it { expect(registry.commands).to be == commands }
    end
  end

  describe '#register' do
    let(:command) { Spec::CustomCommand }

    example_class 'Spec::CustomCommand', Cuprum::Cli::Command

    it 'should define the method' do
      expect(registry)
        .to respond_to(:register)
        .with(1).argument
        .and_keywords(:name)
    end

    describe 'with command: nil' do
      let(:error_message) do
        tools.assertions.error_message_for('class', as: 'command')
      end

      it 'should raise an exception' do
        expect { registry.register(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with command: an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('class', as: 'command')
      end

      it 'should raise an exception' do
        expect { registry.register(Object.new.freeze) }
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
        expect { registry.register(Class.new) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with name: an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('name', as: 'name')
      end

      it 'should raise an exception' do
        expect { registry.register(command, name: Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with name: an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'name')
      end

      it 'should raise an exception' do
        expect { registry.register(command, name: '') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with name: an invalid String' do
      let(:error_message) do
        'name does not match format category:sub_category:do_something'
      end

      it 'should raise an exception' do
        expect { registry.register(command, name: 'UPPER_CASE') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with command: an anonymous command class' do
      let(:command) { Class.new(Cuprum::Cli::Command) }
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'name')
      end

      it 'should raise an exception' do
        expect { registry.register(command) }
          .to raise_error ArgumentError, error_message
      end

      describe 'with name: value' do
        let(:name) { 'custom:scoped:command' }

        it 'should register the command', :aggregate_failures do
          expect { registry.register(command, name:) }
            .to change(registry, :commands)
            .to have_key(name)
        end

        context 'when the registry already defines a command with that name' do
          let(:other_command) { Class.new(Cuprum::Cli::Command) }
          let(:error_message) do
            "command already registered as #{name} - #{other_command.inspect}"
          end

          before(:example) do
            registry.register(other_command, name:)
          end

          it 'should raise an exception' do
            expect { registry.register(command, name:) }
              .to raise_error NameError, error_message
          end
        end
      end
    end

    describe 'with command: a command class' do
      it { expect(registry.register(command)).to be registry }

      it 'should register the command', :aggregate_failures do
        expect { registry.register(command) }
          .to change(registry, :commands)
          .to have_key(command.full_name)
      end

      context 'when the registry already defines a command with that name' do
        let(:other_command) { Class.new(Cuprum::Cli::Command) }
        let(:error_message) do
          "command already registered as #{command.full_name} - " \
            "#{other_command.inspect}"
        end

        before(:example) do
          registry.register(other_command, name: command.full_name)
        end

        it 'should raise an exception' do
          expect { registry.register(command) }
            .to raise_error NameError, error_message
        end
      end

      describe 'with name: value' do
        let(:name) { 'custom:scoped:command' }

        it 'should register the command', :aggregate_failures do
          expect { registry.register(command, name:) }
            .to change(registry, :commands)
            .to have_key(name)
        end

        context 'when the registry already defines a command with that name' do
          let(:other_command) { Class.new(Cuprum::Cli::Command) }
          let(:error_message) do
            "command already registered as #{name} - #{other_command.inspect}"
          end

          before(:example) do
            registry.register(other_command, name:)
          end

          it 'should raise an exception' do
            expect { registry.register(command, name:) }
              .to raise_error NameError, error_message
          end
        end
      end
    end
  end
end
