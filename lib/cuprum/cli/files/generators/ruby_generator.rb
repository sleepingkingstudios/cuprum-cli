# frozen_string_literal: true

require 'cuprum/cli/files/generators'

module Cuprum::Cli::Files::Generators
  # Generator for creating a Ruby source file.
  class RubyGenerator < Cuprum::Cli::Files::Generator
    match_file(/\.rb\z/)

    option :parent_class

    option :ruby,  type: :boolean, default: true
    option :rspec, type: :boolean, default: true, aliases: %i[spec]

    option :ruby_template
    option :rspec_template

    output '%<file_path>s',
      key:           :ruby,
      template_path: File.join(
        Cuprum::Cli::Files::Generators::TEMPLATES_PATH,
        'ruby.rb.erb'
      )

    output File.join('spec', '%<relative_path>s', '%<short_name>s_spec.rb'),
      key:           :rspec,
      template_path: File.join(
        Cuprum::Cli::Files::Generators::TEMPLATES_PATH,
        'rspec.rb.erb'
      )
  end
end
