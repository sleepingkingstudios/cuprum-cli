---
breadcrumbs:
  - name: Documentation
    path: '/'
  - name: Commands
    path: '/commands'
---

# Built-In Commands

`Cuprum::Cli` provides some pre-defined commands for building CLI applications and tools.

## Contents

- [CI Commands](#ci-commands)
  - [RSpec Command](#rspec-command)
  - [RSpec Each Command](#rspec-each-command)
- [File Commands](#file-commands)
  - [New File Command](#new-file-command)

## CI Commands

The following commands are designed to support testing and continuous integration.

- [RSpec Command](#rspec-command)
- [RSpec Each Command](#rspec-each-command)

### RSpec Command

A built-in command to run an [RSpec](https://rspec.info/) test suite.

```bash
bundle exec thor ci:rspec
```

Similar to the `rspec` CLI utility, the takes an optional list of file patterns as well as the following options:

`:color`
: If `true`, forces the terminal output to display in color. If `false`, disables color output. Defaults to `true`.

`:coverage`
: If `false`, sets the `ENV["COVERAGE"]` value to `false`. Defaults to `true`.

`:env`
: Additional `ENV` values to set when running RSpec utility.

`:format`
: The format for the displayed terminal output. Defaults to `'progress'`.

`:gemfile`
: The path to the gemfile used when running RSpec utility.

[Back to Top](#)

### RSpec Each Command

A built-in command to run each RSpec spec file in an individual process. Useful for identifying missing `require` statements or other dependencies that would not be surfaced when running the entire test suite.

```bash
bundle exec thor ci:rspec_each
```

Similar to the `rspec` CLI utility, the takes an optional list of file patterns as well as the following options:

`:color`
: If `true`, forces the terminal output to display in color. If `false`, disables color output. Defaults to `true`.

`:env`
: Additional `ENV` values to set when running RSpec utility.

`:gemfile`
: The path to the gemfile used when running RSpec utility.

[Back to Top](#)

## File Commands

The following commands are used to generate and manage local files.

- [New File Command](#new-file-command)

### New File Command

A built-in command for generating a new source file or files based on defined templates. Automatically handles intermediate directories and supports multiple file generation (such as spec files or view component templates).

```bash
bundle exec thor file:new path/to/file.rb
```

The `file:new` command takes one required argument, the path to the generate file, as well as the following options:

`:directories`
: If `true`, generates intermediate directories, similar to the `-p` flag for the `mkdir` utility. Defaults to `true`.

`:dry_run`
: If `true`, does not generate the actual file, but outputs to the terminal as normal. Defaults to `false`.

`:parent_class`
: The name of the parent class when generating a Ruby class file.

`:templates`
: The templates used when generating the files.

Additionally, the command supports any number of additional boolean options, which are passed to the template when generating the file or files.

[Back to Top](#)

#### Generating Files

Once a file name and options have been set, the new file command matches the file to the [defined templates](#file-templates) to find a matching template. That template, in turn, will parse the file name and options and generate one or more files using that data.

For example, we could define a new Ruby file in `lib/commands/greet.rb`. We want to define a Ruby class that inherits from <a href="https://www.sleepingkingstudios.com/cuprum/commands/" target="_blank">Cuprum::Command</a>, so we pass that in as the parent class.

```bash
bundle exec thor file:new lib/commands/greet.rb "--parent-class=Cuprum::Command"
```

This matches to the built-in Ruby file template, and will automatically generate two files: the class file in `lib/commands/greeter.rb` and a test file in `spec/commands/greeter_spec.rb`.

```ruby
# frozen_string_literal: true

require 'commands'

module Commands
  class Greet < Cuprum::Command

  end
end
```

```ruby
# frozen_string_literal: true

require 'commands/greet'

RSpec.describe Commands::Greet do
  pending
end
```

As you can see, the generated files combine the templates with data parsed from the file name and options to generate the file contents. For example, we can pass the `--no-spec` flag to the command to prevent generating an RSpec file.

If multiple templates match a file name, the most recently added template will be used. This can be used to define specialized templates (such as model files that are checked before generic Ruby files).

[Back to Top](#)

#### File Templates

`Cuprum::Cli` defines its own set of file templates for generating Ruby or RSpec files, but you can override or customize the templates by passing a `:templates` Array to the `file:new` command. The best way to do this is when [registering the command]({{site.baseurl}}/integrations#command-configuration).

Each template is a Hash with three properties:

- The `:name` property is a human-readable name for the template.
- The `:pattern` property is a `Regexp` or a `Proc` that is used to match the file name. The pattern is also used to extract metadata from the file name, such as the name and path of the class when generating a Ruby file.
- The `:templates` property is an Array of Hashes, each of which is the template for a generated file.

The file templates must contain the following properties:

- The `:file_path` property is the relative path to the generated file. It can include values parsed from the file name, using `Kernel#format` semantics.
- The `:template` property is the path to the template file, which is used in generating the file contents.
- The `:types` property is for controlling which files are generated. For example, if the `:types` for a given template are `%i[ruby rspec spec test]`, then passing any of `--no-ruby`, `--no-rspec`, `--no-spec`, or `--no-test` to the command will disable generating that file.

You might decide to add a custom template for a number of reasons - a specialized file type (such as model files), using a loader such as `Zeitwerk` (removing the `require` statements), or if your application uses a different testing library such as `Minitest`.

[Back to Top](#)
