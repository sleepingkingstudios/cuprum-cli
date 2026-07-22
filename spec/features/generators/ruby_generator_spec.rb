# frozen_string_literal: true

require 'cuprum/cli/dependencies/file_system/mock'
require 'cuprum/cli/dependencies/standard_io/mock'
require 'cuprum/cli/files/generators/ruby_generator'

RSpec.describe Cuprum::Cli::Files::Generators::RubyGenerator do
  subject(:generator) { described_class.new(file_path, **constructor_options) }

  let(:files) do
    ruby_template_path = File.join(
      Cuprum::Cli::Files::Generators::TEMPLATES_PATH,
      'ruby.rb.erb'
    )
    rspec_template_path = File.join(
      Cuprum::Cli::Files::Generators::TEMPLATES_PATH,
      'rspec.rb.erb'
    )

    {
      rspec_template_path => File.read(rspec_template_path),
      ruby_template_path  => File.read(ruby_template_path)
    }
  end
  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new(files:) }
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }
  let(:constructor_options) do
    {
      file_system:,
      standard_io:
    }
  end
  let(:file_path) { 'lib/path/to/file.rb' }

  describe '#call' do
    let(:expected_output) do
      <<~TEXT
        Generating file #{file_path}...
        Generating file #{spec_path}...
      TEXT
    end

    describe 'with a top-level file path' do
      let(:file_path) { 'file.rb' }
      let(:spec_path) { 'spec/file_spec.rb' }
      let(:ruby_contents) do
        <<~RUBY
          # frozen_string_literal: true

          module File

          end
        RUBY
      end
      let(:rspec_contents) do
        <<~RUBY
          # frozen_string_literal: true

          require 'file'

          RSpec.describe File do
            pending
          end
        RUBY
      end

      it { expect(generator.call).to be_a_passing_result }

      it 'should output the generated file paths' do
        generator.call

        expect(standard_io.output_stream.string).to be == expected_output
      end

      it 'should generate the Ruby file', :aggregate_failures do
        generator.call

        expect(file_system.read(file_path)).to be == ruby_contents
      end

      it 'should generate the RSpec file', :aggregate_failures do
        generator.call

        expect(file_system.read(spec_path)).to be == rspec_contents
      end

      describe 'with parent_class: value' do
        let(:constructor_options) { super().merge(parent_class: 'Object') }
        let(:ruby_contents) do
          <<~RUBY
            # frozen_string_literal: true

            class File < Object

            end
          RUBY
        end

        it 'should generate the Ruby file', :aggregate_failures do
          generator.call

          expect(file_system.read(file_path)).to be == ruby_contents
        end
      end
    end

    describe 'with a file path with a directory' do
      let(:file_path) { 'lib/file.rb' }
      let(:spec_path) { 'spec/file_spec.rb' }
      let(:ruby_contents) do
        <<~RUBY
          # frozen_string_literal: true

          module File

          end
        RUBY
      end
      let(:rspec_contents) do
        <<~RUBY
          # frozen_string_literal: true

          require 'file'

          RSpec.describe File do
            pending
          end
        RUBY
      end

      it { expect(generator.call).to be_a_passing_result }

      it 'should output the generated file paths' do
        generator.call

        expect(standard_io.output_stream.string).to be == expected_output
      end

      it 'should generate the Ruby file', :aggregate_failures do
        generator.call

        expect(file_system.read(file_path)).to be == ruby_contents
      end

      it 'should generate the RSpec file', :aggregate_failures do
        generator.call

        expect(file_system.read(spec_path)).to be == rspec_contents
      end

      describe 'with parent_class: value' do
        let(:constructor_options) { super().merge(parent_class: 'Object') }
        let(:ruby_contents) do
          <<~RUBY
            # frozen_string_literal: true

            class File < Object

            end
          RUBY
        end

        it 'should generate the Ruby file', :aggregate_failures do
          generator.call

          expect(file_system.read(file_path)).to be == ruby_contents
        end
      end
    end

    describe 'with a file path with a nested directory' do
      let(:file_path) { 'lib/path/to/file.rb' }
      let(:spec_path) { 'spec/path/to/file_spec.rb' }
      let(:ruby_contents) do
        <<~RUBY
          # frozen_string_literal: true

          require 'path/to'

          module Path::To
            module File

            end
          end
        RUBY
      end
      let(:rspec_contents) do
        <<~RUBY
          # frozen_string_literal: true

          require 'path/to/file'

          RSpec.describe Path::To::File do
            pending
          end
        RUBY
      end

      it { expect(generator.call).to be_a_passing_result }

      it 'should output the generated file paths' do
        generator.call

        expect(standard_io.output_stream.string).to be == expected_output
      end

      it 'should generate the Ruby file', :aggregate_failures do
        generator.call

        expect(file_system.read(file_path)).to be == ruby_contents
      end

      it 'should generate the RSpec file', :aggregate_failures do
        generator.call

        expect(file_system.read(spec_path)).to be == rspec_contents
      end

      describe 'with parent_class: value' do
        let(:constructor_options) { super().merge(parent_class: 'Object') }
        let(:ruby_contents) do
          <<~RUBY
            # frozen_string_literal: true

            require 'path/to'

            module Path::To
              class File < Object

              end
            end
          RUBY
        end

        it 'should generate the Ruby file', :aggregate_failures do
          generator.call

          expect(file_system.read(file_path)).to be == ruby_contents
        end
      end
    end
  end
end
