---
breadcrumbs:
  - name: Documentation
    path: '/'
  - name: Versions
    path: '/versions'
version: '0.1'
---

# {{ site.project_metadata.name }}

[Cuprum::Cli]({{site.project_metadata.repository_url}}) is a command-line utility powered by [Cuprum](https://www.sleepingkingstudios.com/cuprum/) that provides tools and utilities for defining command-line tools. It allows developers to define custom CLI commands and register them with integrated command line tools such as Thor.

- [Documentation](#documentation)
- [Getting Started](#getting-started)
- [Reference](#reference)

## Documentation

{% include pages/index-versions.md %}

[Back to Top](#)

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

Set up a [CLI integration](./integrations) and register your commands:

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

You can also define [custom CLI commands]({{site.baseurl/commands}}) using the `Cuprum::Cli::Command` class. `Cuprum::Cli` defines a powerful DSL for quickly defining and configuring commands.

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

For more information on defining commands, see the [commands documentation]({{site.baseurl/commands}}).

[Back to Top](#)

## Reference

The core component in `Cuprum::Cli` is the `Command`.

<ul>
  <li>
    <a href="./commands">Commands</a>
    <br>
    A command defines an action or sequence of actions that can be called from the command line.
    <ul>
      <li>
        <a href="./commands#command-arguments">Arguments</a>
        <br>
        Commands can accept positional arguments from the command line, such as file names.
      </li>
      <li>
        <a href="./commands#command-options">Options</a>
        <br>
        Commands can accept flags or keyword options from the command line.
      </li>
    </ul>
  </li>

  <li>
    <a href="./commands/dependencies">Command Dependencies</a>
    <br>
    <code>Cuprum::Cli</code> commands use dependencies to interact with external functions in a consistent and testable fashion. Defined dependencies include <a href="./commands/dependencies#filesystem">reading from and writing to the file system</a>, <a href="./commands/dependencies#standardio">interacting with the standard IO streams</a>, and <a href="./commands/dependencies#systemcommand">calling system commands</a>.
  </li>
</ul>

### Built-In Commands

`Cuprum::Cli` provides some [pre-defined commands](./commands/built-in) for building CLI applications and tools.

<ul>
  <li>
    <a href="./commands/built-in#ci-commands">CI Commands</a>
    <br>
    Commands for testing your application.
    <ul>
      <li>
        <a href="./commands/built-in#rspec-command">RSpec Command</a>
        <br>
        A command for running <a href="https://rspec.info/" target="_blank">RSpec</a> tests, with configurable options including format, environment and custom gemfile.
      </li>
      <li>
        <a href="./commands/built-in#rspec-each-command">RSpec Each Command</a>
        <br>
        A command for running each RSpec spec file as an isolated test. Useful for identifying missing <code>require</code> statements or other dependencies that would not be surfaced when running the entire test suite.
      </li>
    </ul>
  </li>

  <li>
    <a href="./commands/built-in#file-commands">File Commands</a>
    <br>
    Commands for managing your application's files.
    <ul>
      <li>
        <a href="./commands/built-in#new-file-command">New File Command</a>
        <br>
        A command for generating a new source file or files based on defined templates. Automatically handles intermediate directories and supports multiple file generation (such as spec files or view component templates).
      </li>
    </ul>
  </li>
</ul>

### Integrations

Once a command is defined, `Cuprum::Cli` integrates with an external CLI provider to call the command from the command line.

<ul>
  <li>
    <a href="./integrations">Integrations</a>
    <br>
    Third-party tools that <code>Cuprum::Cli</code> can use to call commands from the command line.
    <ul>
      <li>
        <a href="./integrations#thor">Thor</a>
        <br>
        Using <code>Cuprum::Cli</code> commands with the <a href="https://github.com/rails/thor" target="_blank">Thor</a> toolkit.
      </li>
    </ul>
  </li>
</ul>

For a full list of defined classes and objects, see [Reference](./reference).

[Back to Top](#)
