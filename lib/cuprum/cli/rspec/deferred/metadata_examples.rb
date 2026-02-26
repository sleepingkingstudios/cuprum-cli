# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'cuprum/cli/rspec/deferred'

module Cuprum::Cli::RSpec::Deferred
  # Deferred examples for testing command metadata.
  module MetadataExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_examples 'should implement the Metadata interface' do
      describe '.abstract' do
        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:abstract)
            .with(0).arguments
        end
      end

      describe '.abstract?' do
        it 'should define the class predicate' do
          expect(described_class)
            .to define_predicate(:abstract?)
        end
      end

      describe '.description' do
        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:description)
            .with(0..1).arguments
        end
      end

      describe '.description?' do
        it 'should define the class predicate' do
          expect(described_class)
            .to define_predicate(:description?)
        end
      end

      describe '.full_description' do
        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:full_description)
            .with(0..1).arguments
        end
      end

      describe '.full_description?' do
        it 'should define the class predicate' do
          expect(described_class)
            .to define_predicate(:full_description?)
        end
      end

      describe '.full_name' do
        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:full_name)
            .with(0..1).arguments
        end
      end

      describe '.namespace' do
        include_examples 'should define class reader', :namespace
      end

      describe '.namespace?' do
        it 'should define the class predicate' do
          expect(described_class)
            .to define_predicate(:namespace?)
        end
      end

      describe '.short_name' do
        include_examples 'should define class reader', :short_name
      end
    end

    deferred_examples 'should define metadata for the command' do
      describe '.abstract' do
        it 'should mark the command as abstract' do
          expect { described_class.abstract }
            .to change(described_class, :abstract?)
            .to be true
        end
      end

      describe '.abstract?' do
        it { expect(described_class.abstract?).to be false }

        context 'when the command is abstract' do
          before(:example) do
            described_class.abstract
          end

          it { expect(described_class.abstract?).to be true }
        end

        wrap_deferred 'when the command has a parent command' do
          it { expect(described_class.abstract?).to be false }

          context 'when the command is abstract' do
            before(:example) do
              described_class.abstract
            end

            it { expect(described_class.abstract?).to be true }
          end

          context 'when the parent command is abstract' do
            before(:example) do
              parent_class.abstract
            end

            it { expect(described_class.abstract?).to be false }
          end
        end
      end

      describe '.description' do
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

        context 'when the command is abstract' do
          let(:value) do
            'No one is quite sure what this does.'
          end
          let(:error_message) do
            'unable to set description - Spec::CustomCommand is an abstract ' \
              'class'
          end

          before(:example) { described_class.abstract }

          it 'should raise an exception' do
            expect { described_class.description(value) }.to raise_error(
              described_class::AbstractCommandError,
              error_message
            )
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
              parent_class.description(parent_description)
            end

            it 'should return the parent description' do
              expect(described_class.description).to be == parent_description
            end

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

      describe '.description?' do
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

      describe '.full_description' do
        describe 'with no arguments' do
          it { expect(described_class.full_description).to be nil }
        end

        describe 'with nil' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for('presence', as: 'full_description')
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
            tools
              .assertions
              .error_message_for('presence', as: 'full_description')
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

            it 'should return the value' do
              expect(described_class.full_description(value)).to be == value
            end

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
                expect(described_class.full_description)
                  .to be == full_description
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
              expect(described_class.full_description)
                .to be == parent_description
            end

            context 'when the command has a description' do
              let(:description) do
                'No one is quite sure what this does.'
              end

              before(:example) do
                described_class.description(description)
              end

              it 'should return the description' do
                expect(described_class.full_description).to be == description
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
                expect(described_class.full_description)
                  .to be == full_description
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
              expect(described_class.full_description)
                .to be == parent_description
            end

            context 'when the command has a description' do
              let(:description) do
                'No one is quite sure what this does.'
              end

              before(:example) do
                described_class.description(description)
              end

              it 'should return the parent value' do
                expect(described_class.full_description)
                  .to be == parent_description
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
                expect(described_class.full_description)
                  .to be == full_description
              end
            end
          end
        end

        context 'when the command is abstract' do
          let(:value) do
            <<~DESC
              No one is quite sure what this does.

              ...but it sure looks cool!
            DESC
          end
          let(:error_message) do
            'unable to set full_description - Spec::CustomCommand is an ' \
              'abstract class'
          end

          before(:example) { described_class.abstract }

          it 'should raise an exception' do
            expect { described_class.full_description(value) }.to raise_error(
              described_class::AbstractCommandError,
              error_message
            )
          end
        end
      end

      describe '.full_description?' do
        it { expect(described_class.full_description?).to be false }

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

      describe '.full_name' do
        let(:expected) { 'spec:custom' }

        describe 'with no arguments' do
          it { expect(described_class.full_name).to be == expected }

          wrap_deferred 'when the command is an anonymous class' do
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

          wrap_deferred 'when the command is an anonymous class' do
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

        context 'when the command is abstract' do
          let(:value) { 'category:sub_category:do_something' }
          let(:error_message) do
            'unable to set full_name - Spec::CustomCommand is an abstract class'
          end

          before(:example) { described_class.abstract }

          it 'should raise an exception' do
            expect { described_class.full_name(value) }.to raise_error(
              described_class::AbstractCommandError,
              error_message
            )
          end
        end
      end

      describe '.namespace' do
        it { expect(described_class.namespace).to be == 'spec' }

        wrap_deferred 'when the command is an anonymous class' do
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

      describe '.namespace?' do
        it { expect(described_class.namespace?).to be true }

        wrap_deferred 'when the command is an anonymous class' do
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

      describe '.short_name' do
        let(:expected) { 'custom' }

        it { expect(described_class.short_name).to be == expected }

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
  end
end
