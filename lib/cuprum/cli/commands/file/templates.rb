# frozen_string_literal: true

require 'cuprum/cli/commands/file'

module Cuprum::Cli::Commands::File
  # Namespace for defining templates for generated files.
  module Templates
    RSPEC_PATTERN = <<~PATTERN.strip.then { |pattern| /#{pattern}/xo }
      \\A
      (?<root_path>\\w+#{File::SEPARATOR})?
      (?<relative_path>(\\w+#{File::SEPARATOR})*)
      (?<base_name>\\w+)_spec\\.rb
      \\z
    PATTERN
    private_constant :RSPEC_PATTERN

    RUBY_PATTERN = <<~PATTERN.strip.then { |pattern| /#{pattern}/xo }
      \\A
      (?<root_path>\\w+#{File::SEPARATOR})?
      (?<relative_path>(\\w+#{File::SEPARATOR})*)
      (?<base_name>\\w+)\\.rb
      \\z
    PATTERN
    private_constant :RUBY_PATTERN

    TEMPLATES_PATH =
      File
      .join(
        Cuprum::Cli.gem_path,
        'lib',
        'cuprum',
        'cli',
        'commands',
        'file',
        'templates'
      )
      .freeze
    private_constant :TEMPLATES_PATH

    # Default templates used to generate Ruby and RSpec files.
    DEFAULT_TEMPLATES = [
      {
        name:      'RSpec File',
        pattern:   RSPEC_PATTERN,
        templates: {
          file_path: '%<root_path>s%<relative_path>s%<base_name>s_spec.rb',
          template:  File.join(TEMPLATES_PATH, 'rspec.rb.erb'),
          types:     %i[ruby rspec spec test]
        }
      },
      {
        name:      'Ruby File (With Spec)',
        pattern:   RUBY_PATTERN,
        templates: [
          {
            file_path: '%<root_path>s%<relative_path>s%<base_name>s.rb',
            template:  File.join(TEMPLATES_PATH, 'ruby.rb.erb'),
            type:      :ruby
          },
          {
            file_path: 'spec/%<relative_path>s%<base_name>s_spec.rb',
            template:  File.join(TEMPLATES_PATH, 'rspec.rb.erb'),
            types:     %i[ruby rspec spec test]
          }
        ]
      }
    ].then do |ary|
      SleepingKingStudios::Tools::Toolbelt.instance.array_tools.deep_freeze(ary)
    end
  end
end
