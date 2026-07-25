# frozen_string_literal: true

require 'cuprum/cli/files/generators'

module Cuprum::Cli::Files::Generators
  # Generator for creating an RSpec source file.
  class RSpecGenerator < Cuprum::Cli::Files::Generator
    match_file(/_spec\.rb\z/)

    option :rspec_template

    output '%<file_path>s',
      key:      :rspec,
      template: File.join(
        Cuprum::Cli::Files::Generators::TEMPLATES_PATH,
        'rspec.rb.erb'
      )
  end
end
