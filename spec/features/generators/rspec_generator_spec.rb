# frozen_string_literal: true

require 'cuprum/cli/dependencies/file_system/mock'
require 'cuprum/cli/dependencies/standard_io/mock'
require 'cuprum/cli/files/generators/rspec_generator'

RSpec.describe Cuprum::Cli::Files::Generators::RSpecGenerator do
  subject(:generator) { described_class.new(file_path, **constructor_options) }

  let(:files) do
    rspec_template_path = File.join(
      Cuprum::Cli::Files::Generators::TEMPLATES_PATH,
      'rspec.rb.erb'
    )

    { rspec_template_path => File.read(rspec_template_path) }
  end
  let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new(files:) }
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }
  let(:constructor_options) do
    {
      file_system:,
      standard_io:
    }
  end
  let(:file_path) { 'spec/path/to/file_spec.rb' }

  describe '#call' do
    let(:expected_output) do
      "Generating file #{file_path}...\n"
    end

    describe 'with a top-level file path' do
      let(:file_path) { 'file_spec.rb' }
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

      it 'should generate the RSpec file', :aggregate_failures do
        generator.call

        expect(file_system.read(file_path)).to be == rspec_contents
      end
    end

    describe 'with a file path with a directory' do
      let(:file_path) { 'spec/file_spec.rb' }
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

      it 'should generate the RSpec file', :aggregate_failures do
        generator.call

        expect(file_system.read(file_path)).to be == rspec_contents
      end
    end

    describe 'with a file path with a nested directory' do
      let(:file_path) { 'spec/path/to/file_spec.rb' }
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

      it 'should generate the RSpec file', :aggregate_failures do
        generator.call

        expect(file_system.read(file_path)).to be == rspec_contents
      end
    end
  end
end
