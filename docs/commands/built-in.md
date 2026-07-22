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
  - [Generators](#generators)
  - [Generator Matching](#generator-matching)
  - [Generator Outputs](#generator-outputs)

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

`:generators`
: The generators used when matching and creating the files.

`:quiet`
: Suppresses non-error output to the terminal.

`:verbose`
: Displays the full contents of the generated files in the terminal. Very useful when combined with `--dry-run` to preview the file contents.

Additionally, the command supports any number of additional options, which are passed to the generator when generating the file or files. Note that if the matching generator does not support a given option, it will respond with an error.

[Back to Top](#)

#### Generators

`Cuprum::Cli` uses [generator classes](./file-generators) to define the files created by the `file:new` command.

Each generator defines a pattern or patterns that are used when determining which generator is called for a given request. It also defines a set of output files - these are the files generated when the generator is called. A generator can have multiple outputs, allowing `Cuprum::Cli` to create multiple files from a single command, such as a source file and the associated spec.

Finally, generators can define additional options that are used when building the contents of the generated files. For example, the Ruby generator allows specifying a `--parent-class` option, which changes the file contents from creating a new `Module` to creating a new `Class` with the specified parent.

`Cuprum::Cli` defines two built-in generators:

- The [Ruby](./file-generators#ruby-generator) generator creates a Ruby source file and corresponding RSpec spec file.
- The [RSpec](./file-generators#rspec-generator) generator creates an RSpec spec file.

[Back to Top](#)

##### Generator Matching

When the `file:new` command is called, the first step is to find the matching generator for that input path and options. Each generators defines a matching pattern or patterns.

- `Proc` patterns match on both the input path and options. If the proc returns `true`, that generator is match.
- `Regexp` patterns match on the input path. If the regex matches the path, that generator is a match.
- `String` patterns match on the input path. If the path ends with the string, that generator is a match.

If there is more than one generator that matches the file path and options, the last generator defined is used. This allows overriding default generators, or defining generators for more specific contexts, such as a web application's model files or controllers.

If there are no matching generators, the `file:new` command returns with an error.

[Back to Top](#)

##### Generator Outputs

Each generator defines one or more outputs. When that generator is called, it creates a new file for each of those outputs, using the file path and template defined for that output. For example, the [Ruby](./file-generators#ruby-generator) generator defines one output for the Ruby file and one output for the RSpec file.

`Cuprum::Cli` automatically extracts a number of properties from the given input path, such as the file name, file extension, and directory path. These properties can be used to customize the output path or the contents of the generated file, along with the options passed by the user to `file:new`.

For example, for the input path `lib/space/rocket.rb` and option `--parent-class=Vehicle`, the Ruby generator creates the following files.

In `lib/space/rocket.rb`:

```ruby
# frozen_string_literal: true

require 'space'

module Space
  class Rocket < Vehicle

  end
end
```

In `spec/space/rocket_spec.rb`:

```ruby
# frozen_string_literal: true

require 'space/rocket'

RSpec.describe Space::Rocket do
  pending
end
```

Some generators allow you to pass a custom template for a specific output, or even disable that output entirely. For example, if you pass the `--skip-rspec` option to the Ruby template, the generator will not create the RSpec file.

[Back to Top](#)
