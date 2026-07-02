---
breadcrumbs:
  - name: Documentation
    path: '/'
---

# Integrations

`Cuprum::Cli` integrates with third-party tools to call [commands](./commands) from the command line.

- [Thor](#thor)

## Thor

`Cuprum::Cli` defines an integration with the <a href="https://github.com/rails/thor" target="_blank">Thor</a> toolkit.

### Registering Commands

To use the `Thor` integration, open or create a file with `.thor` extname to define your Thor commands and create an instance of `Cuprum::Cli::Integrations::Thor::Registry`.

```ruby
# In tasks.thor:
require 'cuprum/cli/integrations/thor/registry'

registry = Cuprum::Cli::Integrations::Thor::Registry.new
```

To register a command, use the `registry.register(command)` method.

```ruby
registry.register Cuprum::Cli::Commands::Ci::RSpecCommand
```

This will register the command for `Thor` using its default name, description and options.

```
% bundle exec thor list
ci
--
thor ci:rspec ...FILE_PATTERNS       # Runs an RSpec command.
```

[Back to Top](#)

#### Naming Commands

You can customize the name or description of the command by passing `:full_name` or `:description` values to `#register`.

```ruby
registry.register Cuprum::Cli::Commands::Ci::RSpecCommand,
  full_name: 'tests:rspec:all'
```

[Back to Top](#)

#### Command Configuration

If you pass `:arguments` or `:options` to `#register`, those parameters will be added to any parameters from the command line when the command is called. This allows you to define multiple variants of a command with pre-defined configuration.

```ruby
registry.register Cuprum::Cli::Commands::Ci::RSpecCommand
registry.register Cuprum::Cli::Commands::Ci::RSpecCommand,
  full_name:   'ci:rspec:sinatra4',
  description: 'Runs the RSpec tests against Sinatra 4.X',
  options:     { gemfile: 'gemfiles/sinatra_4.gemfile' }
```

[Back to Top](#)
