# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in cuprum-cli.gemspec
gemspec

gem 'plumbum',
  git: 'https://github.com/sleepingkingstudios/plumbum'

gem 'sleeping_king_studios-tools',
  git: 'https://github.com/sleepingkingstudios/sleeping_king_studios-tools'

group :development, :test do
  gem 'rspec', '~> 3.13'
  gem 'rspec-sleeping_king_studios', '~> 2.8', '>= 2.8.3'

  gem 'rubocop',       '~> 1.82'
  gem 'rubocop-rspec', '~> 3.8'

  gem 'simplecov', '~> 0.22'
end
