# frozen_string_literal: true

require 'cuprum/cli/metadata'

RSpec.describe Cuprum::Cli::Metadata do
  let(:described_class) { Spec::CustomCommand }
  let(:concern)         { Cuprum::Cli::Metadata } # rubocop:disable RSpec/DescribedClass

  deferred_context 'when the command has a parent command' do
    let(:parent_class)    { Spec::CustomCommand }
    let(:described_class) { Spec::SubclassCommand }

    example_class 'Spec::SubclassCommand', 'Spec::CustomCommand'
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

  describe '#description' do
    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:description)
        .with(0..1).arguments
    end

    describe 'with no arguments' do
      it { expect(described_class.description).to be nil }
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'description')
      end

      it 'should raise an exception' do
        expect { described_class.description(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('name', as: 'description')
      end

      it 'should raise an exception' do
        expect { described_class.description(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'description')
      end

      it 'should raise an exception' do
        expect { described_class.description('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a non-empty String' do
      let(:value) do
        'No one is quite sure what this does.'
      end

      it { expect(described_class.description(value)).to be == value }

      it 'should set the description' do
        expect { described_class.description(value) }
          .to change(described_class, :description)
          .to be == value
      end
    end

    wrap_deferred 'when the command has a parent command' do
      it { expect(described_class.description).to be nil }

      context 'when the command has a description' do
        let(:description) do
          'No one is quite sure what this does.'
        end

        before(:example) do
          described_class.description(description)
        end

        it { expect(described_class.description).to be == description }
      end

      context 'when the parent command has a description' do
        let(:parent_description) do
          'A thing of mystery.'
        end

        before(:example) do
          Spec::CustomCommand.description(parent_description)
        end

        it { expect(described_class.description).to be == parent_description }

        context 'when the command has a description' do
          let(:description) do
            'No one is quite sure what this does.'
          end

          before(:example) do
            described_class.description(description)
          end

          it { expect(described_class.description).to be == description }
        end
      end
    end
  end

  describe '#description?' do
    it 'should define the class predicate' do
      expect(described_class)
        .to define_predicate(:description?)
        .with_value(false)
    end

    context 'when the command has a description' do
      let(:description) do
        'No one is quite sure what this does.'
      end

      before(:example) do
        described_class.description(description)
      end

      it { expect(described_class.description?).to be true }
    end

    wrap_deferred 'when the command has a parent command' do
      it { expect(described_class.description?).to be false }

      context 'when the command has a description' do
        let(:description) do
          'No one is quite sure what this does.'
        end

        before(:example) do
          described_class.description(description)
        end

        it { expect(described_class.description?).to be true }
      end

      context 'when the parent command has a description' do
        let(:parent_description) do
          'A thing of mystery.'
        end

        before(:example) do
          Spec::CustomCommand.description(parent_description)
        end

        it { expect(described_class.description?).to be true }
      end
    end
  end

  describe '#full_description' do
    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:full_description)
        .with(0..1).arguments
    end

    describe 'with no arguments' do
      it { expect(described_class.full_description).to be nil }
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'full_description')
      end

      it 'should raise an exception' do
        expect { described_class.full_description(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('name', as: 'full_description')
      end

      it 'should raise an exception' do
        expect { described_class.full_description(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'full_description')
      end

      it 'should raise an exception' do
        expect { described_class.full_description('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a non-empty String' do
      let(:value) do
        <<~DESC
          No one is quite sure what this does.

          ...but it sure looks cool!
        DESC
      end

      it { expect(described_class.full_description(value)).to be == value }

      it 'should set the full description' do
        expect { described_class.full_description(value) }
          .to change(described_class, :full_description)
          .to be == value
      end
    end

    context 'when the command has a description' do
      let(:description) do
        'No one is quite sure what this does.'
      end

      before(:example) do
        described_class.description(description)
      end

      it { expect(described_class.full_description).to be == description }

      describe 'with a non-empty String' do
        let(:value) do
          <<~DESC
            No one is quite sure what this does.

            ...but it sure looks cool!
          DESC
        end

        it { expect(described_class.full_description(value)).to be == value }

        it 'should set the full description' do
          expect { described_class.full_description(value) }
            .to change(described_class, :full_description)
            .to be == value
        end
      end
    end

    wrap_deferred 'when the command has a parent command' do
      it { expect(described_class.full_description).to be nil }

      context 'when the command has a description' do
        let(:description) do
          'No one is quite sure what this does.'
        end

        before(:example) do
          described_class.description(description)
        end

        it { expect(described_class.full_description).to be == description }

        context 'when the command has a full description' do
          let(:full_description) do
            <<~DESC
              No one is quite sure what this does.

              ...but it sure looks cool!
            DESC
          end

          before(:example) do
            described_class.full_description(full_description)
          end

          it 'should return the full description' do
            expect(described_class.full_description).to be == full_description
          end
        end
      end

      context 'when the command has a full description' do
        let(:full_description) do
          <<~DESC
            No one is quite sure what this does.

            ...but it sure looks cool!
          DESC
        end

        before(:example) do
          described_class.full_description(full_description)
        end

        it 'should return the full description' do
          expect(described_class.full_description).to be == full_description
        end
      end

      context 'when the parent command has a description' do
        let(:parent_description) do
          'A thing of mystery.'
        end

        before(:example) do
          Spec::CustomCommand.description(parent_description)
        end

        it 'should return the parent value' do
          expect(described_class.full_description).to be == parent_description
        end

        context 'when the command has a description' do
          let(:description) do
            'No one is quite sure what this does.'
          end

          before(:example) do
            described_class.description(description)
          end

          it { expect(described_class.full_description).to be == description }
        end

        context 'when the command has a full description' do
          let(:full_description) do
            <<~DESC
              No one is quite sure what this does.

              ...but it sure looks cool!
            DESC
          end

          before(:example) do
            described_class.full_description(full_description)
          end

          it 'should return the full description' do
            expect(described_class.full_description).to be == full_description
          end
        end
      end

      context 'when the parent command has a full description' do
        let(:parent_description) do
          'A thing of mystery.'
        end

        before(:example) do
          Spec::CustomCommand.full_description(parent_description)
        end

        it 'should return the parent value' do
          expect(described_class.full_description).to be == parent_description
        end

        context 'when the command has a description' do
          let(:description) do
            'No one is quite sure what this does.'
          end

          before(:example) do
            described_class.description(description)
          end

          it 'should return the parent value' do
            expect(described_class.full_description).to be == parent_description
          end
        end

        context 'when the command has a full description' do
          let(:full_description) do
            <<~DESC
              No one is quite sure what this does.

              ...but it sure looks cool!
            DESC
          end

          before(:example) do
            described_class.full_description(full_description)
          end

          it 'should return the full description' do
            expect(described_class.full_description).to be == full_description
          end
        end
      end
    end
  end

  describe '#full_description?' do
    it 'should define the class predicate' do
      expect(described_class)
        .to define_predicate(:full_description?)
        .with_value(false)
    end

    context 'when the command has a description' do
      let(:description) do
        'No one is quite sure what this does.'
      end

      before(:example) do
        described_class.description(description)
      end

      it { expect(described_class.full_description?).to be false }
    end

    context 'when the command has a full description' do
      let(:full_description) do
        <<~DESC
          No one is quite sure what this does.

          ...but it sure looks cool!
        DESC
      end

      before(:example) do
        described_class.full_description(full_description)
      end

      it { expect(described_class.full_description?).to be true }
    end

    wrap_deferred 'when the command has a parent command' do
      context 'when the command has a description' do
        let(:description) do
          'No one is quite sure what this does.'
        end

        before(:example) do
          described_class.description(description)
        end

        it { expect(described_class.full_description?).to be false }
      end

      context 'when the command has a full description' do
        let(:full_description) do
          <<~DESC
            No one is quite sure what this does.

            ...but it sure looks cool!
          DESC
        end

        before(:example) do
          described_class.full_description(full_description)
        end

        it { expect(described_class.full_description?).to be true }
      end

      context 'when the parent command has a description' do
        let(:parent_description) do
          'A thing of mystery.'
        end

        before(:example) do
          Spec::CustomCommand.description(parent_description)
        end

        it { expect(described_class.full_description?).to be false }
      end

      context 'when the parent command has a full description' do
        let(:parent_description) do
          'A thing of mystery.'
        end

        before(:example) do
          Spec::CustomCommand.full_description(parent_description)
        end

        it { expect(described_class.full_description?).to be true }
      end
    end
  end

  describe '#full_name' do
    let(:expected) { 'spec:custom' }

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:full_name)
        .with(0..1).arguments
    end

    describe 'with no arguments' do
      it { expect(described_class.full_name).to be == expected }

      context 'when the command is an anonymous class' do
        let(:described_class) do
          Class.new do
            include Cuprum::Cli::Metadata
          end
        end

        it { expect(described_class.full_name).to be nil }
      end

      context 'when the namespace includes ::Commands' do
        let(:expected) { 'scope:do_something' }
        let(:described_class) do
          Spec::Namespace::Commands::Scope::DoSomething
        end

        example_class 'Spec::Namespace::Commands::Scope::DoSomething',
          'Spec::CustomCommand'

        it { expect(described_class.full_name).to be == expected }
      end
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'full_name')
      end

      it 'should raise an exception' do
        expect { described_class.full_name(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for('name', as: 'full_name')
      end

      it 'should raise an exception' do
        expect { described_class.full_name(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for('presence', as: 'full_name')
      end

      it 'should raise an exception' do
        expect { described_class.full_name('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an invalid String' do
      let(:error_message) do
        'full_name does not match format category:sub_category:do_something'
      end

      it 'should raise an exception' do
        expect { described_class.full_name(described_class.name) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an valid String' do
      let(:value) { 'do_something' }

      it { expect(described_class.full_name(value)).to be == value }

      it 'should set the full name' do
        expect { described_class.full_name(value) }
          .to change(described_class, :full_name)
          .to be == value
      end
    end

    describe 'with an valid scoped String' do
      let(:value) { 'category:sub_category:do_something' }

      it { expect(described_class.full_name(value)).to be == value }

      it 'should set the full name' do
        expect { described_class.full_name(value) }
          .to change(described_class, :full_name)
          .to be == value
      end
    end

    wrap_deferred 'when the command has a parent command' do
      let(:expected) { 'spec:subclass' }

      it { expect(described_class.full_name).to be == expected }

      context 'when the command is an anonymous class' do
        let(:described_class) do
          Class.new(parent_class) do
            include Cuprum::Cli::Metadata

            def self.name
              Class.instance_method(:name).bind(self).call
            end
          end
        end
        let(:expected) { 'spec:custom' }

        it { expect(described_class.full_name).to be == expected }

        context 'when the parent command defines a full name' do
          let(:expected) { 'category:sub_category:do_something' }

          before(:example) do
            parent_class.full_name 'category:sub_category:do_something'
          end

          it { expect(described_class.full_name).to be == expected }
        end

        context 'when the parent command is an anonymous class' do
          let(:parent_class) do
            Class.new do
              include Cuprum::Cli::Metadata

              def self.name
                Class.instance_method(:name).bind(self).call
              end
            end
          end

          it { expect(described_class.full_name).to be nil }
        end
      end
    end
  end

  describe '#namespace' do
    include_examples 'should define class reader', :namespace, 'spec'

    context 'when the command is an anonymous class' do
      let(:described_class) do
        Class.new do
          include Cuprum::Cli::Metadata
        end
      end

      it { expect(described_class.namespace).to be nil }
    end

    context 'when the command has an unscoped name' do
      before(:example) do
        described_class.full_name 'do_something'
      end

      it { expect(described_class.namespace).to be nil }
    end

    context 'when the command has a scoped name' do
      let(:expected) { 'category:sub_category' }

      before(:example) do
        described_class.full_name 'category:sub_category:do_something'
      end

      it { expect(described_class.namespace).to be == expected }
    end
  end

  describe '#namespace?' do
    it 'should define the class predicate' do
      expect(described_class)
        .to define_predicate(:namespace?)
        .with_value(true)
    end

    context 'when the command is an anonymous class' do
      let(:described_class) do
        Class.new do
          include Cuprum::Cli::Metadata
        end
      end

      it { expect(described_class.namespace?).to be false }
    end

    context 'when the command has an unscoped name' do
      before(:example) do
        described_class.full_name 'do_something'
      end

      it { expect(described_class.namespace?).to be false }
    end

    context 'when the command has a scoped name' do
      let(:expected) { 'category:sub_category' }

      before(:example) do
        described_class.full_name 'category:sub_category:do_something'
      end

      it { expect(described_class.namespace?).to be true }
    end
  end

  describe '#short_name' do
    let(:expected) { 'custom' }

    include_examples 'should define class reader', :short_name, -> { expected }

    context 'when the command is an anonymous class' do
      let(:described_class) do
        Class.new do
          include Cuprum::Cli::Metadata
        end
      end

      it { expect(described_class.short_name).to be nil }
    end

    context 'when the command has a custom name' do
      let(:expected) { 'do_something' }

      before(:example) do
        described_class.full_name 'category:sub_category:do_something'
      end

      it { expect(described_class.short_name).to be == expected }
    end
  end
end
