# frozen_string_literal: true

require 'cuprum/cli/files/templates/file_template'

RSpec.describe Cuprum::Cli::Files::Templates::FileTemplate do
  subject(:template) { described_class.new(file_path:, **options) }

  let(:file_path) { 'templates/docs.md.erb' }
  let(:options)   { {} }

  describe '.build' do
    it { expect(described_class).to respond_to(:build).with(1).argument }

    describe 'with a generic file path' do
      let(:file_path) { 'templates/docs.md' }

      it 'should build a FileTemplate with engine: nil' do
        expect(described_class.build(file_path))
          .to be_a(described_class)
          .and have_attributes(engine: nil, file_path:)
      end
    end

    describe 'with a file path ending with .erb' do
      let(:file_path) { 'templates/docs.md.erb' }

      it 'should build a FileTemplate with engine: nil' do # rubocop:disable RSpec/ExampleLength
        expect(described_class.build(file_path))
          .to be_a(described_class)
          .and have_attributes(
            engine:    Cuprum::Cli::Files::Engines::ERB,
            file_path:
          )
      end
    end
  end

  describe '.members' do
    let(:expected) { %i[engine file_path file_system] }

    it { expect(described_class.members).to be == expected }
  end

  describe '#call' do
    it { expect(template).to respond_to(:call).with(0).arguments }

    context 'when the template file does not exist' do
      let(:expected_error) do
        Cuprum::Cli::Files::Errors::MissingTemplate.new(
          message:       'unable to generate file',
          template_path: file_path
        )
      end

      it 'should return a failing result' do
        expect(template.call)
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    context 'when the template file exists' do
      let(:file_path) do
        File.join(
          Cuprum::Cli.gem_path,
          'spec',
          'support',
          'templates',
          'docs.md.erb'
        )
      end
      let(:expected_value) { File.read(file_path) }

      it 'should return a passing result' do
        expect(template.call)
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end

    context 'when initialized with file_system: value' do
      let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new }
      let(:options)     { super().merge(file_system:) }

      context 'when the template file does not exist' do
        let(:expected_error) do
          Cuprum::Cli::Files::Errors::MissingTemplate.new(
            message:       'unable to generate file',
            template_path: file_path
          )
        end

        it 'should return a failing result' do
          expect(template.call)
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the template file exists' do
        let(:contents) do
          <<~MARKDOWN
            # Greetings, Starfighter

            You have been recruited by the Star League to defend the frontier
            against Xur and the Ko-Dan armada!
          MARKDOWN
        end
        let(:expected_value) { contents }

        before(:example) do
          file_system.create_directory('templates')
          file_system.write_file(file_path, contents)
        end

        it 'should return a passing result' do
          expect(template.call)
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end
  end

  describe '#engine' do
    include_examples 'should define reader', :engine, nil

    context 'when initialized with engine: value' do
      let(:engine)  { Cuprum::Cli::Files::Engines::ERB }
      let(:options) { super().merge(engine:) }

      it { expect(template.engine).to be engine }
    end
  end

  describe '#file_path' do
    include_examples 'should define reader', :file_path, -> { file_path }
  end

  describe '#file_system' do
    include_examples 'should define reader',
      :file_system,
      -> { Cuprum::Cli::Dependencies.provider.get('file_system') }

    context 'when initialized with file_system: value' do
      let(:file_system) { Cuprum::Cli::Dependencies::FileSystem::Mock.new }
      let(:options)     { super().merge(file_system:) }

      it { expect(template.file_system).to be file_system }
    end
  end
end
