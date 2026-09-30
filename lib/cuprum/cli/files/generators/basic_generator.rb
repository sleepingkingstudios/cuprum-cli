# frozen_string_literal: true

require 'cuprum/cli/files/generators'

module Cuprum::Cli::Files::Generators
  # Generator for creating a file with specified file path and contents.
  class BasicGenerator < Cuprum::Cli::Files::Generator
    option :contents,  type: :string, required: true

    option :file_path, type: :string, required: true

    output '%<file_path>s',
      template: Cuprum::Cli::Files::Templates::BasicTemplate.new
  end
end
