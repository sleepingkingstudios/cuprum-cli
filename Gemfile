# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in cuprum-cli.gemspec
gemspec

gem 'async', '~> 2.37' # Versions 2.38 and above require Ruby 3.3.
gem 'thor', '~> 1.5'

group :development, :test do
  gem 'appraisal', '~> 2.5'

  gem 'byebug', '~> 12.0'
  gem 'irb', '~> 1.16'
  gem 'readline'

  gem 'rspec', '~> 3.13'
  gem 'rspec-sleeping_king_studios', '~> 2.8', '>= 2.8.3'

  gem 'rubocop',       '~> 1.88'
  gem 'rubocop-rspec', '~> 3.10'

  gem 'simplecov', '~> 0.22'
end

group :docs do
  gem 'jekyll', '~> 4.4'
  gem 'jekyll-theme-dinky', '~> 0.2'
  gem 'logger', '~> 1.7'

  # Use Kramdown to parse GFM-dialect Markdown.
  gem 'kramdown-parser-gfm', '~> 1.1'

  gem 'sleeping_king_studios-docs', '~> 0.2', '>= 0.2.1'

  # Use Webrick as local content server.
  gem 'webrick', '~> 1.9'

  gem 'yard', '~> 0.9', require: false
end
