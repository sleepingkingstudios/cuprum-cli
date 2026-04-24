# frozen_string_literal: true

require 'cuprum/cli'

RSpec.describe Cuprum::Cli::Commands::File::NewCommand do
  subject(:command) { described_class.new(standard_io:) }

  let(:standard_io) do
    Cuprum::Cli::Dependencies::StandardIo::Mock.new
  end
  let(:arguments) { [file_path] }
  let(:options)   { { dry_run: true, verbose: true } }

  define_method :call_command do
    command.call(*arguments, **options).tap do |result|
      expect(result).to be_a_passing_result
    end
  end

  describe 'with a Ruby file path' do
    let(:file_path) { 'vendor/file.rb' }
    let(:expected) do
      <<~TEXT
        Generating file vendor/file.rb...

          # frozen_string_literal: true

          module File

          end

        Generating file spec/file_spec.rb...

          # frozen_string_literal: true

          require 'file'

          RSpec.describe File do
            pending
          end

      TEXT
    end

    it 'should generate the Ruby and RSpec files' do
      call_command

      expect(standard_io.output_stream.string).to be == expected
    end

    describe 'with a nested path' do
      let(:file_path) { 'vendor/path/to/file.rb' }
      let(:expected) do
        <<~TEXT
          Generating file vendor/path/to/file.rb...

            # frozen_string_literal: true

            require 'path/to'

            module Path::To
              module File

              end
            end

          Generating file spec/path/to/file_spec.rb...

            # frozen_string_literal: true

            require 'path/to/file'

            RSpec.describe Path::To::File do
              pending
            end

        TEXT
      end

      it 'should generate the Ruby and RSpec files' do
        call_command

        expect(standard_io.output_stream.string).to be == expected
      end

      describe 'with parent_class: value' do
        let(:options) { super().merge(parent_class: 'Stream') }
        let(:expected) do
          <<~TEXT
            Generating file vendor/path/to/file.rb...

              # frozen_string_literal: true

              require 'path/to'

              module Path::To
                class File < Stream

                end
              end

            Generating file spec/path/to/file_spec.rb...

              # frozen_string_literal: true

              require 'path/to/file'

              RSpec.describe Path::To::File do
                pending
              end

          TEXT
        end

        it 'should generate the Ruby and RSpec files' do
          call_command

          expect(standard_io.output_stream.string).to be == expected
        end
      end
    end

    describe 'with parent_class: value' do
      let(:options) { super().merge(parent_class: 'Stream') }
      let(:expected) do
        <<~TEXT
          Generating file vendor/file.rb...

            # frozen_string_literal: true

            class File < Stream

            end

          Generating file spec/file_spec.rb...

            # frozen_string_literal: true

            require 'file'

            RSpec.describe File do
              pending
            end

        TEXT
      end

      it 'should generate the Ruby and RSpec files' do
        call_command

        expect(standard_io.output_stream.string).to be == expected
      end
    end

    describe 'with spec: false' do
      let(:options) { super().merge(extra_flags: { spec: false }) }
      let(:expected) do
        <<~TEXT
          Generating file vendor/file.rb...

            # frozen_string_literal: true

            module File

            end

        TEXT
      end

      it 'should generate the Ruby file only' do
        call_command

        expect(standard_io.output_stream.string).to be == expected
      end
    end
  end

  describe 'with an RSpec file path' do
    let(:file_path) { 'vendor/file_spec.rb' }
    let(:expected) do
      <<~TEXT
        Generating file vendor/file_spec.rb...

          # frozen_string_literal: true

          require 'file'

          RSpec.describe File do
            pending
          end

      TEXT
    end

    it 'should generate the RSpec file' do
      call_command

      expect(standard_io.output_stream.string).to be == expected
    end

    describe 'with a nested path' do
      let(:file_path) { 'vendor/path/to/file_spec.rb' }
      let(:expected) do
        <<~TEXT
          Generating file vendor/path/to/file_spec.rb...

            # frozen_string_literal: true

            require 'path/to/file'

            RSpec.describe Path::To::File do
              pending
            end

        TEXT
      end

      it 'should generate the RSpec file' do
        call_command

        expect(standard_io.output_stream.string).to be == expected
      end
    end
  end
end
