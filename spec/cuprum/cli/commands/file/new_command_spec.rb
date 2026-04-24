# frozen_string_literal: true

require 'cuprum/cli/commands/file/new_command'
require 'cuprum/cli/rspec/deferred/arguments_examples'
require 'cuprum/cli/rspec/deferred/options_examples'

RSpec.describe Cuprum::Cli::Commands::File::NewCommand do
  include Cuprum::Cli::RSpec::Deferred::ArgumentsExamples
  include Cuprum::Cli::RSpec::Deferred::OptionsExamples

  subject(:command) do
    described_class.new(file_system:, standard_io:)
  end

  let(:ruby_template) do
    <<~ERB
      # frozen_string_literal: true

      <%= parent_class ? 'class' : 'module' %> Greeter<%= " < \#{parent_class}" if parent_class %>
        def greet = puts 'Greetings, programs!'
      end
    ERB
  end
  let(:rspec_template) do
    <<~RUBY
      # frozen_string_literal: true

      RSpec.describe Greeter do
        it { expect(true).to be false }
      end
    RUBY
  end
  let(:files) do
    {
      'templates' => {
        'ruby.rb.erb' => StringIO.new(ruby_template),
        'rspec.rb'    => StringIO.new(rspec_template)
      }
    }
  end
  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new(files:) }
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }

  include_deferred 'should define argument',
    0,
    :file_path,
    type:     String,
    required: true

  include_deferred 'should define option',
    :directories,
    type:    :boolean,
    default: true
  include_deferred 'should define option',
    :dry_run,
    type:    :boolean,
    default: false
  include_deferred 'should define option', :parent_class, type: String
  include_deferred 'should define option',
    :templates,
    type:    Array,
    default: Cuprum::Cli::Commands::File::Templates::DEFAULT_TEMPLATES
  include_deferred 'should define option',
    :extra_flags,
    type:     :boolean,
    variadic: true

  include_deferred 'should define --quiet option'

  include_deferred 'should define --verbose option'

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe '#call' do
    deferred_examples 'should generate file' do |file_path:, using_template:|
      it 'should generate the file' do # rubocop:disable RSpec/ExampleLength
        command.call(*arguments, **options)

        params   = { parent_class: options[:parent_class] }
        template = file_system.read(using_template)
        template =
          Cuprum::Cli::Commands::File::RenderErb
          .new
          .call(template, **params)
          .value

        expect(file_system.read(file_path)).to be == template
      end
    end

    deferred_examples 'should not generate file' do |file_path:|
      it 'should generate the file' do
        command.call(*arguments, **options)

        expect(file_system.file?(file_path)).to be false
      end
    end

    let(:file_path) { 'lib/file.rb' }
    let(:templates) do
      ruby_pattern = <<~PATTERN.strip.then { |pattern| /#{pattern}/xo }
        \\A
        (?<root_path>\\w+#{File::SEPARATOR})?
        (?<relative_path>(\\w+#{File::SEPARATOR})*)
        (?<base_name>\\w+)\\.rb
        \\z
      PATTERN

      [
        {
          name:      'Plain Text',
          pattern:   '.txt',
          templates: { template: 'templates/plain_text.txt' }
        },
        {
          name:      'Ruby Source Code',
          pattern:   ruby_pattern,
          templates: [
            {
              template: 'templates/ruby.rb.erb',
              type:     :ruby
            },
            {
              file_path: 'spec/%<relative_path>s%<base_name>s_spec.rb',
              template:  'templates/rspec.rb',
              types:     %i[ruby rspec]
            }
          ]
        }
      ]
    end
    let(:arguments) { [file_path] }
    let(:options)   { { templates: } }
    let(:expected_value) do
      ['lib/file.rb', 'spec/file_spec.rb']
    end
    let(:expected_output) do
      <<~TEXT
        Generating file lib/file.rb...
        Generating file spec/file_spec.rb...
      TEXT
    end
    let(:rendered_ruby) do
      Cuprum::Cli::Commands::File::RenderErb
        .new
        .call(ruby_template, parent_class: options[:parent_class])
        .value
    end
    let(:rendered_rspec) do
      rspec_template
    end

    it { expect(command).to be_callable }

    it 'should return a passing result' do
      expect(command.call(*arguments, **options))
        .to be_a_passing_result
        .with_value(expected_value)
    end

    include_deferred 'should generate file',
      file_path:      'lib/file.rb',
      using_template: 'templates/ruby.rb.erb'

    include_deferred 'should generate file',
      file_path:      'spec/file_spec.rb',
      using_template: 'templates/rspec.rb'

    it 'should report the file paths to STDOUT' do
      command.call(*arguments, **options)

      expect(standard_io.output_stream.string).to be == expected_output
    end

    describe 'with dry_run: true' do
      let(:options) { super().merge(dry_run: true) }

      it 'should return a passing result' do
        expect(command.call(*arguments, **options))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      include_deferred 'should not generate file',
        file_path: 'lib/file.rb'

      include_deferred 'should not generate file',
        file_path: 'spec/file_spec.rb'
    end

    describe 'with extra_flags: template filter' do
      let(:options) { super().merge(extra_flags: { rspec: false }) }
      let(:expected_value) do
        %w[lib/file.rb]
      end
      let(:expected_output) do
        <<~TEXT
          Generating file lib/file.rb...
        TEXT
      end

      it 'should return a passing result' do
        expect(command.call(*arguments, **options))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      include_deferred 'should generate file',
        file_path:      'lib/file.rb',
        using_template: 'templates/ruby.rb.erb'

      include_deferred 'should not generate file',
        file_path: 'spec/file_spec.rb'

      it 'should report the file paths to STDOUT' do
        command.call(*arguments, **options)

        expect(standard_io.output_stream.string).to be == expected_output
      end

      describe 'with verbose: true' do
        let(:options) { super().merge(verbose: true) }
        let(:expected_output) do
          <<~TEXT
            Generating file lib/file.rb...

            #{
              rendered_ruby
              .each_line
              .map { |line| line == "\n" ? "\n" : "  #{line}" }
              .join
            }
          TEXT
        end

        it 'should return a passing result' do
          expect(command.call(*arguments, **options))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        include_deferred 'should generate file',
          file_path:      'lib/file.rb',
          using_template: 'templates/ruby.rb.erb'

        include_deferred 'should not generate file',
          file_path: 'spec/file_spec.rb'

        it 'should report the file paths to STDOUT' do
          command.call(*arguments, **options)

          expect(standard_io.output_stream.string).to be == expected_output
        end
      end
    end

    describe 'with parent_class: value' do
      let(:options) { super().merge(parent_class: 'Person') }

      it 'should return a passing result' do
        expect(command.call(*arguments, **options))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      include_deferred 'should generate file',
        file_path:      'lib/file.rb',
        using_template: 'templates/ruby.rb.erb'

      include_deferred 'should generate file',
        file_path:      'spec/file_spec.rb',
        using_template: 'templates/rspec.rb'

      it 'should report the file paths to STDOUT' do
        command.call(*arguments, **options)

        expect(standard_io.output_stream.string).to be == expected_output
      end

      describe 'with verbose: true' do
        let(:options) { super().merge(verbose: true) }
        let(:expected_output) do
          <<~TEXT
            Generating file lib/file.rb...

            #{
              rendered_ruby
              .each_line
              .map { |line| line == "\n" ? "\n" : "  #{line}" }
              .join
            }
            Generating file spec/file_spec.rb...

            #{
              rendered_rspec
              .each_line
              .map { |line| line == "\n" ? "\n" : "  #{line}" }
              .join
            }
          TEXT
        end

        it 'should return a passing result' do
          expect(command.call(*arguments, **options))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        include_deferred 'should generate file',
          file_path:      'lib/file.rb',
          using_template: 'templates/ruby.rb.erb'

        include_deferred 'should generate file',
          file_path:      'spec/file_spec.rb',
          using_template: 'templates/rspec.rb'

        it 'should report the file paths and contents to STDOUT' do
          command.call(*arguments, **options)

          expect(standard_io.output_stream.string).to be == expected_output
        end
      end
    end

    describe 'with quiet: true' do
      let(:options) { super().merge(quiet: true) }

      it 'should return a passing result' do
        expect(command.call(*arguments, **options))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      include_deferred 'should generate file',
        file_path:      'lib/file.rb',
        using_template: 'templates/ruby.rb.erb'

      include_deferred 'should generate file',
        file_path:      'spec/file_spec.rb',
        using_template: 'templates/rspec.rb'

      it 'should not output to STDOUT or STDERR' do
        command.call(*arguments, **options)

        expect(standard_io.combined_stream.string).to be == ''
      end
    end

    describe 'with verbose: true' do
      let(:options) { super().merge(verbose: true) }
      let(:expected_output) do
        <<~TEXT
          Generating file lib/file.rb...

          #{
            rendered_ruby
            .each_line
            .map { |line| line == "\n" ? "\n" : "  #{line}" }
            .join
          }
          Generating file spec/file_spec.rb...

          #{
            rendered_rspec
            .each_line
            .map { |line| line == "\n" ? "\n" : "  #{line}" }
            .join
          }
        TEXT
      end

      it 'should return a passing result' do
        expect(command.call(*arguments, **options))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      include_deferred 'should generate file',
        file_path:      'lib/file.rb',
        using_template: 'templates/ruby.rb.erb'

      include_deferred 'should generate file',
        file_path:      'spec/file_spec.rb',
        using_template: 'templates/rspec.rb'

      it 'should report the file paths and contents to STDOUT' do
        command.call(*arguments, **options)

        expect(standard_io.output_stream.string).to be == expected_output
      end
    end

    context 'when there is not a matching template' do
      let(:file_path) { 'lib/file.md' }
      let(:expected_error) do
        Cuprum::Cli::Errors::Files::TemplateNotResolved.new(
          file_path:,
          message:   'no template matching file path'
        )
      end

      it 'should return a failing result' do
        expect(command.call(*arguments, **options))
          .to be_a_failing_result
          .with_error(expected_error)
      end

      it 'should not output to STDOUT' do
        expect(standard_io.combined_stream.string).to be == ''
      end

      it 'should not update the filesystem' do
        expect { command.call(*arguments, **options) }
          .not_to change(file_system, :files)
      end
    end

    context 'when all templates are filtered out' do
      let(:options) { super().merge(extra_flags: { ruby: false }) }
      let(:expected_error) do
        Cuprum::Cli::Errors::Files::TemplateNotResolved.new(
          file_path:,
          message:   'all templates filtered out',
          options:   { except: %i[ruby] }
        )
      end

      it 'should return a failing result' do
        expect(command.call(*arguments, **options))
          .to be_a_failing_result
          .with_error(expected_error)
      end

      it 'should not output to STDOUT' do
        expect(standard_io.combined_stream.string).to be == ''
      end

      it 'should not update the filesystem' do
        expect { command.call(*arguments, **options) }
          .not_to change(file_system, :files)
      end
    end

    context 'when the template file does not exist' do
      let(:file_path) { 'lib/file.txt' }
      let(:expected_error) do
        Cuprum::Cli::Errors::Files::MissingTemplate.new(
          message:       "unable to generate file #{file_path}",
          template_path: 'templates/plain_text.txt'
        )
      end

      it 'should return a failing result' do
        expect(command.call(*arguments, **options))
          .to be_a_failing_result
          .with_error(expected_error)
      end

      it 'should not output to STDOUT' do
        expect(standard_io.combined_stream.string).to be == ''
      end

      it 'should not update the filesystem' do
        expect { command.call(*arguments, **options) }
          .not_to change(file_system, :files)
      end
    end

    context 'when the file directory does not exist' do
      let(:file_path) { 'lib/path/to/file.rb' }
      let(:expected_value) do
        ['lib/path/to/file.rb', 'spec/path/to/file_spec.rb']
      end
      let(:expected_output) do
        <<~TEXT
          Generating file lib/path/to/file.rb...
          Generating file spec/path/to/file_spec.rb...
        TEXT
      end

      it 'should return a passing result' do
        expect(command.call(*arguments, **options))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      include_deferred 'should generate file',
        file_path:      'lib/path/to/file.rb',
        using_template: 'templates/ruby.rb.erb'

      include_deferred 'should generate file',
        file_path:      'spec/path/to/file_spec.rb',
        using_template: 'templates/rspec.rb'

      it 'should report the file paths to STDOUT' do
        command.call(*arguments, **options)

        expect(standard_io.output_stream.string).to be == expected_output
      end

      context 'when initialized with directories: false' do
        let(:options) { super().merge(directories: false) }
        let(:expected_error) do
          Cuprum::Cli::Errors::Files::FileNotWriteable.new(
            file_path: 'lib/path/to/file.rb',
            reason:    'directory not found'
          )
        end

        it 'should return a failing result' do
          expect(command.call(*arguments, **options))
            .to be_a_failing_result
            .with_error(expected_error)
        end

        it 'should not output to STDOUT' do
          expect(standard_io.combined_stream.string).to be == ''
        end

        it 'should not update the filesystem' do
          expect { command.call(*arguments, **options) }
            .not_to change(file_system, :files)
        end
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
