# frozen_string_literal: true

require_relative 'lib/cuprum/cli/version'

Gem::Specification.new do |gem|
  gem.name =       'cuprum-cli'
  gem.version     = Cuprum::Cli::VERSION
  gem.authors     = ['Rob "Merlin" Smith']
  gem.email       = ['sleepingkingstudios@gmail.com']

  gem.summary     = 'A command-line utility powered by Cuprum.'
  gem.description = <<~DESCRIPTION.gsub(/\s+/, ' ').strip
    Provides tools and utilities for defining command-line tools.
  DESCRIPTION
  gem.homepage    = 'http://sleepingkingstudios.com'
  gem.license     = 'MIT'
  gem.metadata    = {
    'bug_tracker_uri'       => 'https://github.com/sleepingkingstudios/cuprum-cli/issues',
    'changelog_uri'         => 'https://github.com/sleepingkingstudios/cuprum-cli/CHANGELOG.md',
    'homepage_uri'          => gem.homepage,
    'source_code_uri'       => 'https://github.com/sleepingkingstudios/cuprum-cli',
    'rubygems_mfa_required' => 'true'
  }
  gem.required_ruby_version = ['>= 3.2', '< 5']

  gem.require_paths = ['lib']
  gem.files         = Dir[
    'bin/cuprum-cli',
    'lib/**/*.rb',
    'LICENSE',
    '*.md'
  ]
  gem.bindir        = 'bin'

  gem.add_dependency 'cuprum', '~> 1.3', '>= 1.3.1'
end
