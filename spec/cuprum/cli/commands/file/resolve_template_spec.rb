# frozen_string_literal: true

require 'cuprum/cli/commands/file/resolve_template'

RSpec.describe Cuprum::Cli::Commands::File::ResolveTemplate do
  subject(:command) { described_class.new(templates:) }

  deferred_context 'when initialized with templates: value' do
    let(:templates) do
      markdown_pattern =
        /\A(?<relative_path>(\w+#{File::SEPARATOR})*)(?<short_name>\w+)\.md\z/
      ruby_matcher = lambda do |file_path|
        next unless file_path.end_with?('.rb')

        *dir_names, base_name = file_path.split(File::SEPARATOR)

        {
          base_name:,
          relative_path: dir_names.join(File::SEPARATOR)
        }
      end

      [
        {
          name:      'String matching',
          pattern:   '.txt',
          templates: { template: 'plain_text.txt' }
        },
        {
          name:      'Regexp matching',
          pattern:   markdown_pattern,
          templates: {
            template: 'markdown.md',
            type:     :documentation
          }
        },
        {
          name:      'Ruby matching',
          pattern:   ruby_matcher,
          templates: [
            {
              name:     'Documentation file',
              template: 'yard.md',
              type:     :doc
            },
            {
              name:     'Source file',
              template: 'ruby.rb',
              type:     :ruby
            },
            {
              name:     'Spec file',
              template: 'ruby_spec.rb',
              types:    %i[ruby spec]
            }
          ]
        },
        {
          name:      'Ruby fallback',
          pattern:   '.rb',
          templates: { template: 'ruby.rb' }
        }
      ]
    end
  end

  let(:templates) { [] }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:templates)
    end
  end

  describe '#call' do
    let(:file_path) { 'path/to/file.yml' }
    let(:options)   { {} }
    let(:parameters) do
      {
        file_path:,
        base_name:  'file.yml',
        dir_name:   'path/to',
        ext_name:   '.yml',
        short_name: 'file'
      }
    end
    let(:filtered) do
      next matching[:templates] if matching[:templates].is_a?(Array)

      [matching[:templates]]
    end
    let(:expected_value) do
      [filtered, parameters]
    end

    define_method :call_command do
      command.call(file_path, **options)
    end

    it 'should define the method' do
      expect(command)
        .to be_callable
        .with(1).argument
        .and_keywords(:except, :only)
    end

    describe 'with non-matching file path' do
      let(:expected_error) do
        Cuprum::Cli::Errors::Files::TemplateNotResolved.new(
          file_path:,
          message:   'no template matching file path'
        )
      end

      it 'should return a failing result' do
        expect(call_command)
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    wrap_deferred 'when initialized with templates: value' do
      describe 'with non-matching file path' do
        let(:expected_error) do
          Cuprum::Cli::Errors::Files::TemplateNotResolved.new(
            file_path:,
            message:   'no template matching file path'
          )
        end

        it 'should return a failing result' do
          expect(call_command)
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'with a file path matching a Proc matcher' do
        let(:file_path) { 'path/to/file.rb' }
        let(:matching) do
          templates.find { |hsh| hsh[:name] == 'Ruby matching' }
        end
        let(:parameters) do
          super().merge(
            base_name:     'file.rb',
            ext_name:      '.rb',
            relative_path: 'path/to'
          )
        end

        it 'should return a passing result' do
          expect(call_command)
            .to be_a_passing_result
            .with_value(expected_value)
        end

        describe 'with except: value matching all items' do
          let(:options) { super().merge(except: %i[doc ruby]) }
          let(:expected_error) do
            Cuprum::Cli::Errors::Files::TemplateNotResolved.new(
              file_path:,
              message:   'all templates filtered out',
              options:
            )
          end

          it 'should return a failing result' do
            expect(call_command)
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end

        describe 'with except: value matching some items' do
          let(:options) { super().merge(except: %i[spec]) }
          let(:filtered) do
            super().reject do |template|
              template[:type] == :spec || template[:types]&.include?(:spec)
            end
          end

          it 'should return a passing result' do
            expect(call_command)
              .to be_a_passing_result
              .with_value(expected_value)
          end
        end

        describe 'with except: value matching no items' do
          let(:options) { super().merge(except: %i[php]) }

          it 'should return a passing result' do
            expect(call_command)
              .to be_a_passing_result
              .with_value(expected_value)
          end
        end

        describe 'with only: value matching all items' do
          let(:options) { super().merge(only: %i[doc ruby]) }

          it 'should return a passing result' do
            expect(call_command)
              .to be_a_passing_result
              .with_value(expected_value)
          end
        end

        describe 'with only: value matching some items' do
          let(:options) { super().merge(only: %i[ruby]) }
          let(:filtered) do
            super().select do |template|
              template[:type] == :ruby || template[:types]&.include?(:ruby)
            end
          end

          it 'should return a passing result' do
            expect(call_command)
              .to be_a_passing_result
              .with_value(expected_value)
          end
        end

        describe 'with only: value matching no items' do
          let(:options) { super().merge(only: %i[rbs]) }
          let(:expected_error) do
            Cuprum::Cli::Errors::Files::TemplateNotResolved.new(
              file_path:,
              message:   'all templates filtered out',
              options:
            )
          end

          it 'should return a failing result' do
            expect(call_command)
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end

        describe 'with both except: and only: filters' do
          let(:options) { super().merge(except: %i[spec], only: :ruby) }
          let(:filtered) do
            super()
              .select do |template|
                template[:type] == :ruby || template[:types]&.include?(:ruby)
              end # rubocop:disable Style/MultilineBlockChain
              .reject do |template|
                template[:type] == :spec || template[:types]&.include?(:spec)
              end
          end

          it 'should return a passing result' do
            expect(call_command)
              .to be_a_passing_result
              .with_value(expected_value)
          end
        end
      end

      describe 'with a file path matching a Regexp matcher' do
        let(:file_path) { 'path/to/file.md' }
        let(:matching) do
          templates.find { |hsh| hsh[:name] == 'Regexp matching' }
        end
        let(:parameters) do
          super().merge(
            base_name:     'file.md',
            ext_name:      '.md',
            relative_path: 'path/to/'
          )
        end

        it 'should return a passing result' do
          expect(call_command)
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with a file path matching a String matcher' do
        let(:file_path) { 'path/to/file.txt' }
        let(:matching) do
          templates.find { |hsh| hsh[:name] == 'String matching' }
        end
        let(:parameters) do
          super().merge(base_name: 'file.txt', ext_name: '.txt')
        end

        it 'should return a passing result' do
          expect(call_command)
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end
  end

  describe '#templates' do
    include_examples 'should define reader', :templates, -> { templates }

    wrap_deferred 'when initialized with templates: value' do
      it { expect(command.templates).to be == templates }
    end
  end
end
