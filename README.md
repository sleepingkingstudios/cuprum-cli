# Cuprum::Cli

A command-line utility powered by [Cuprum](https://www.sleepingkingstudios.com/cuprum/) that provides tools and utilities for defining command-line tools.

<blockquote>
  Read The
  <a href="https://www.sleepingkingstudios.com/cuprum-cli" target="_blank">
    Documentation
  </a>
</blockquote>

## About

### Documentation

Documentation is generated using [YARD](https://yardoc.org/), and can be generated locally using the `yard` gem.

### License

Copyright (c) 2026 Rob Smith

`Cuprum::Cli` is released under the [MIT License](https://opensource.org/licenses/MIT).

### Contribute

The canonical repository for this gem is located at https://github.com/sleepingkingstudios/cuprum-cli.

To report a bug or submit a feature request, please use the [Issue Tracker](https://github.com/sleepingkingstudios/cuprum-cli/issues).

To contribute code, please fork the repository, make the desired updates, and then provide a [Pull Request](https://github.com/sleepingkingstudios/cuprum-cli/pulls). Pull requests must include appropriate tests for consideration, and all code must be properly formatted.

### Code of Conduct

Please note that the `Cuprum::Cli` project is released with a [Contributor Code of Conduct](https://github.com/sleepingkingstudios/cuprum-cli/blob/master/CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.

### Local Development

The test suite for `Cuprum::Cli` is written using [RSpec](https://rspec.info/), with optional integration dependencies managed using [Appraisal](https://github.com/thoughtbot/appraisal).

To run the general test suite:

```bash
bundle exec rspec
```

To run the test suite including the `Thor` integration:

```bash
BUNDLER_GEMFILE=gemfiles/integrations_thor.gemfile INTEGRATION=thor bundle exec rspec
```

To run the [RuboCop](https://rubocop.org/) linter:

```bash
bundle exec rubocop
```

## Getting Started

Add the gem to your Gemfile or gemspec:

```ruby
group :development, :test do
  gem 'cuprum-cli'
end
```

To ensure that dependent libraries are loaded, call the `Cuprum::Cli` initializer:

- In the initializer for your project:

  ```ruby
  module Space
    @initializer = SleepingKingStudios::Tools::Toolbox::Initializer.new do
      Cuprum::Cli.initializer.call
    end
  end
  ```

- Or, in the entry points of your application (such as a `bin` script or `spec_helper.rb`).

Set up a <a href="https://www.sleepingkingstudios.com/cuprum-cli/integrations" target="_blank">CLI integration</a> and register your commands:

```ruby
# In tasks.thor:
require 'cuprum/cli/integrations/thor/registry'

Cuprum::Cli.initializer.call

registry = Cuprum::Cli::Integrations::Thor::Registry.new

registry.register Cuprum::Cli::Commands::Ci::RSpecCommand
registry.register Cuprum::Cli::Commands::Ci::RSpecCommand,
  full_name:   'ci:rspec:sinatra4',
  description: 'Runs the RSpec tests against Sinatra 4.X',
  options:     { gemfile: 'gemfiles/sinatra_4.gemfile' }
```

Finally, you can call the commands from your CLI tool:

```
% bundle exec thor list
ci
--
thor ci:rspec ...FILE_PATTERNS       # Runs an RSpec command.
thor ci:rspec:sinatra4 ...FILE_PATTERNS  # Runs the RSpec tests against Sinatra 4.X
```

### Defining Commands

You can also define custom CLI commands using the `Cuprum::Cli::Command` class. `Cuprum::Cli` defines a powerful DSL for quickly defining and configuring commands.

```ruby
class PingCommand < Cuprum::Cli::Command
  dependency :system_command

  argument :service_url,
    default:     'www.example.com',
    description: 'The URL of the remote service',
    type:        String

  option :interval,
    aliases:     'i',
    default:     0.1,
    description: 'The interval between pings',
    type:        Float

  option :max_count,
    aliases:     %w[c],
    default:     5,
    description: 'The total number of pings sent to the server',
    type:        Integer

  private

  def format_options
    # The ping command uses a non-standard options format.
    options = +''

    options << "-c#{max_count}"
    options << "-i#{interval}"
    options << '-q' # Only display the summary line.
  end

  def process
    system_command.capture(
      'ping',
      arguments: [format_options, service_url]
    )
  end
end
```

Now that we've defined a custom command, we can register it in our CLI integration:

```ruby
registry.register PingCommand
registry.register PingCommand,
  full_name: 'ping:github',
  options:   { service_url: 'github.com' }
```

For more information on defining commands, see the <a href="https://www.sleepingkingstudios.com/cuprum-cli/commands" target="_blank">commands documentation</a>.
