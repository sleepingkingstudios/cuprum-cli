---
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

Set up a [CLI integration]({{site.baseurl}}/integrations) and register your commands:

```ruby
# In tasks.thor:
require 'cuprum/cli/integrations/thor/registry'

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

[Back to Top](#)

## Reference

The core component in `Cuprum::Cli` is the `Command`.

<ul>
  <li>
    <a href="{{site.baseurl}}/commands">Commands</a>
    <br>
    A command defines an action or sequence of actions that can be called from the command line.
    <ul>
      <li>
        <a href="{{site.baseurl}}/commands#command-arguments">Arguments</a>
        <br>
        Commands can accept positional arguments from the command line, such as file names.
      </li>
      <li>
        <a href="{{site.baseurl}}/commands#command-options">Options</a>
        <br>
        Commands can accept flags or keyword options from the command line.
      </li>
    </ul>
  </li>

  <li>
    <a href="{{site.baseurl}}/commands/dependencies">Command Dependencies</a>
    <br>
    <code>Cuprum::Cli</code> commands use dependencies to interact with external functions in a consistent and testable fashion. Defined dependencies include <a href="{{site.baseurl}}/commands/dependencies#filesystem">reading from and writing to the file system</a>, <a href="{{site.baseurl}}/commands/dependencies#standardio">interacting with the standard IO streams</a>, and <a href="{{site.baseurl}}/commands/dependencies#systemcommand">calling system commands</a>.
  </li>
</ul>

### Built-In Commands

`Cuprum::Cli` provides some [pre-defined commands]({{site.baseurl}}/commands/built-in) for building CLI applications and tools.

<ul>
  <li>
    <a href="{{site.baseurl}}/commands/built-in#ci-commands">CI Commands</a>
    <br>
    Commands for testing your application.
    <ul>
      <li>
        <a href="{{site.baseurl}}/commands/built-in#rspec-command">RSpec Command</a>
        <br>
        A command for running <a href="https://rspec.info/" target="_blank">RSpec</a> tests, with configurable options including format, environment and custom gemfile.
      </li>
      <li>
        <a href="{{site.baseurl}}/commands/built-in#rspec-each-command">RSpec Each Command</a>
        <br>
        A command for running each RSpec spec file as an isolated test. Useful for identifying missing <code>require</code> statements or other dependencies that would not be surfaced when running the entire test suite.
      </li>
    </ul>
  </li>

  <li>
    <a href="{{site.baseurl}}/commands/built-in#file-commands">File Commands</a>
    <br>
    Commands for managing your application's files.
    <ul>
      <li>
        <a href="{{site.baseurl}}/commands/built-in#new-file-command">New File Command</a>
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
    <a href="{{site.baseurl}}/integrations">Integrations</a>
    <br>
    Third-party tools that <code>Cuprum::Cli</code> can use to call commands from the command line.
    <ul>
      <li>
        <a href="{{site.baseurl}}/integrations#thor">Thor</a>
        <br>
        Using <code>Cuprum::Cli</code> commands with the <a href="https://github.com/rails/thor" target="_blank">Thor</a> toolkit.
      </li>
    </ul>
  </li>
</ul>

For a full list of defined classes and objects, see [Reference](./reference).

[Back to Top](#)
