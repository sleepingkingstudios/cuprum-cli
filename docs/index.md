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
</ul>
For a full list of defined classes and objects, see [Reference](./reference).

[Back to Top](#)
