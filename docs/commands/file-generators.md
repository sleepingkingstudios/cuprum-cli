---
breadcrumbs:
  - name: Documentation
    path: '/'
  - name: Commands
    path: '/commands'
---

# File Generators

Generators are used by the [New File command](./built-in#new-file-command) to define the output files generated for a given input path and options.

```ruby
class MarkdownGenerator < Cuprum::Cli::Files::Generator
  match_file(/\.md\z/)

  option :template

  output '%<file_path>s', template: 'templates/docs_template.md.erb'
end
```

For a full list of available methods, see the [Reference documentation](../reference/cuprum/cli/files/generator).

## Contents

- [Defining Generators](#defining-generators)
  - [Generator Matching](#generator-matching)
  - [Generator Outputs](#generator-outputs)
  - [Generator Options](#generator-options)
- [Templates](#templates)
  - [File Templates](#file-templates)
  - [String Templates](#string-templates)
  - [Template Engines](#template-engines)
- [Using Generators](#using-generators)
  - [Generating Files](#generating-files)
  - [Filtering Outputs](#filtering-outputs)
- [Built-In Generators](#built-in-generators)
  - [Ruby Generator](#ruby-generator)
  - [RSpec Generator](#rspec-generator)

## Defining Generators

To define a generator, we declare a new `class` that inherits from `Cuprum::Cli::Files::Generator`:

```ruby
class MarkdownGenerator < Cuprum::Cli::Files::Generator
  match_file(/\.md\z/)

  output '%<file_path>s', template: 'templates/docs_template.md.erb'
end
```

Each generator class requires two parts - at least one [match statement](#generator-matching), and at least one [output statement](#generator-outputs). Match statements are used when deciding which generator to use for a given input file (and options), while output statements determine what files are output by the generator.

In our above example, we declare that the generator will match input files ending with the `.md` extension, and that when called, it will output a file at the specified path using the template at `'templates/docs_template.md.erb'`.

[Back to Top](#)

### Generator Matching

A generator's match statements are used to determine which generator is invoked by the [New File command](./built-in#new-file-command), or more generally whether the generator can generate output files of the requested type.

Each generator must have at least one match statement. If a generator has more than one match, then any file path and options that matches *any* of the match statements will match the generator.

```ruby
class YamlGenerator < Cuprum::Cli::Files::Generator
  match_file(/\.yaml\z/)

  match_file(/\.yml\z/)
end
```

The above generator will match file paths that end in either `.yaml` or `.yml`. Once a generator has defined match statements, they can be checked using the `generator_class.matches?(file_path, **options)` class method, which returns `true` if any match statements match the given file name and options, or `false` if none of the match statements match.

To declare a match statement, use the `.match_file(pattern)` method, which must be provided a pattern to match, either a [String](#string-matchers) or a [Regexp](#regexp-matchers). For more complex matching, you can instead pass a block to `.match_file { |file_path, **options| }` (see [Block Matchers](#block-matchers), below).

[Back to Top](#)

#### String Matchers

A generator with a `String` matcher will match any file path that *ends with* the given String. For example, the `match_file('.txt')` matcher will match against any file that has a `.txt` extension, and the `match_file('_spec.rb')` matcher will match against RSpec files that end with `_spec.rb`.

[Back to Top](#)

#### Regexp Matchers

A generator with a `Regexp` matcher will match any file path that matches the given pattern. For example, the `match_file(/\.txt\z/)` matcher will match any file that has a `.txt` extension, and the `match_file(/\Aspec/)` matcher will match any file in the `spec` directory.

[Back to Top](#)

#### Block Matchers

You can exercise fine-grained control over a generator's matches by passing a block to `.match_file { |file_path, **options| }`. The block must take one positional argument (the input file path) and any number of keywords, the options passed into the generator. If the block returns `true` (or any truthy value), the generator matches the file path and options; if the block returns `false` (or `nil`), the generator will not match.

Block matchers are the only match statements that allow matching against the options passed to the generator as well as the filename. For example, a generator for model files might match against both files in the the `lib/models` directory as well as when the `--type=model` option is set.

[Back to Top](#)

### Generator Outputs

A generator's output statements are used to determine which files will be created when the generator is called. Each output has up to three parts: the file path for the generated file, an optional key, and an optional template.

```ruby
class DocsGenerator < Cuprum::Cli::Files::Generator
  match_file '.md'

  option :template, required: true

  output '%<file_path>s'

  output File.join('%<dir_name>s', '%<short_name>.yml'),
    key:      :data,
    template: 'templates/docs/data.yml.erb'
end
```

The above generator will generate two files:

- The first file is a Markdown file at the specified file path. Since there is no defined template, the user will need to define the template when calling the generator using the `--template` option.
- The second file is a YAML file in the same directory and with the same short name but with a `.yml` extension. The YAML file will be generating using the `'templates/docs/data.yml.erb'` template, and has the unique `:data` key.

For example, if we call this generator with a file path of `docs/errors/unknown_error.md` and option `--template=templates/docs/doc.md.yml`, it will generate two files:

- A Markdown file at `docs/errors/unknown_error.md`, using the template at `'templates/docs/doc.md.yml'`.
- A YAML file at `docs/errors/unknown_error.yml`, using the template at `'templates/docs/data.yml.erb'`.

[Back to Top](#)

#### File Paths

Each output must specify an output path, which is a `String` which can contain format directives (the same format as used in `Kernel#sprintf`; see the Ruby documentation for full details). These format directives will be resolved when the generator is called.

In addition to the values from the [generator options](#generator-options), each generator parses the input file path for a number of parameters that are useful for defining new files relative to the input file path. The following examples use an input file path of `"lib/path/to/file.rb"`:

`:base_name`
: The last segment of the file path, including the file extension. Example: `"file.rb"`.

`:dir_name`
: The directory path from the file path, relative to the working directory. Example: `"lib/path/to"`.

`:ext_name`
: The extension of the file path, including the leading period character. Example: `".rb"`.

`:file_path`
: The full file path. Example: `"lib/path/to/file.rb"`.

`:relative_path`
: The *second and later* segments of the directory path, or an empty String if the path is too short. Example: `"path/to"`.

`:root_path`
: The *first* segment of the directory path, or an empty String if the path is too short. Example: `"lib"``.

`:short_name`
: The last segment of the file path, excluding the file extension. Example: `"file"`.

Each of these parameters can be used in the file path and when [evaluating the file template](#generating-files), as can each of the generator option values.

[Back to Top](#)

#### Output Templates

Each output can also define a template, which can be one of three types of value:

- A [template object](#templates), such as a [StringTemplate](#string-templates) or [FileTemplate](#file-templates).
- A single-line `String`, which is interpreted as a file path and converted to a [FileTemplate](#file-templates).
- A multi-line `String`, which is interpreted as a raw template literal and converted to a [StringTemplate](#string-templates).

The template (along with the generator options and [the parameters parsed from the input path](#file-paths)) is used to generate the contents of the output file.

The template can be omitted from the output, in which case the generator must define a corresponding template option and the end user pass the desired template file path when calling the generator. See [custom templates](#custom-templates) for more information.

[Back to Top](#)

#### Output Keys

When a generator defines multiple outputs, it uses the output `:key` to identify specific a specific output. This is used when [filtering outputs](#filtering-outputs) or using a [custom template](#custom-templates), but it can also be a useful signal for the developer when reading a generator class. If the key is omitted, the output is defined with a key of `:default`.

If you try and define an output *on the same generator class* with an existing key, `Cuprum::Cli` will raise an `OutputAlreadyExistsError`. However, you can freely redefine outputs on a *subclass of a generator class* - this allows you to customize the behavior of the generator for a particular context.

[Back to Top](#)

### Generator Options

Generators define the same [Options DSL](../commands#command-options) as Commands, and can define new options using the `.option(option_name, **opts)` class method. Any option values passed to the generator can be used when [generating file paths](#file-paths) and when [rendering the contents of an output](#generating-files).

Additionally, `Cuprum::Cli` also allows [filtering outputs](#filtering-outputs) and [customizing templates](#custom-templates) based on the options passed to the generator.

[Back to Top](#)

## Templates

`Cuprum::Cli` uses `Template` objects internally to determine the contents of generated files. A template may represent [a file on the file system](#file-templates) or may wrap [a raw template value](#string-templates). In addition, each template defines an optional [engine](#engine), which is used to process the raw template and the [generator parameters](#generator-parameters) to build the final contents of the output file.

You can also define custom template classes by defining a subclass of `Cuprum::Cli::Files::Template`. The subclass must define a `#call` method that either returns a `String` (the raw template) or a failing `Cuprum::Result` with a `Cuprum::Error`. For example, you could define a template that retrieves the contents from a web url:

```ruby
UrlTemplate = Cuprum::Cli::Files::Template.define(:url) do
  def call
    conn = Faraday.new(url:) do |faraday|
      faraday.response :raise_error # raise Faraday::Error on status code 4xx or 5xx
    end

    response = conn.get(url)
    response.body
  rescue Faraday::Error => exception
    error = Cuprum::Error.new(message: exception.message)

    failure(error)
  end
end
```

[Back to Top](#)

### File Templates

A `FileTemplate` represents a template definition stored on the local file system.

```ruby
file_path = 'templates/docs.md.erb'
template  = Cuprum::Cli::Files::Templates::FileTemplate.build(file_path)
template.file_path
#=> 'templates/docs.md.erb'
template.engine
#=> 'cuprum.cli.files.engines.erb'
```

If you pass a file path to `FileTemplate.build`, it will automatically detect [ERB files](#erb-engine) that end with a `.erb` suffix. You can also manually generate a template using `FileTemplate.new(engine:, file_path:)`.

[Back to Top](#)

### String Templates

A `StringTemplate` represents a template definition stored as a `String` literal.

```ruby
raw_template = <<~MARKDOWN
  # Greetings, Starfighter

  You have been recruited by the Star League to defend the frontier
  against Xur and the Ko-Dan armada!
MARKDOWN
template     = Cuprum::Cli::Files::Templates::StringTemplate.build(raw_template)
template.engine
#=> nil
template.raw_template
#=> "# Greetings, Starfighter\n\n..."
```

You can also manually generate a template using `StringTemplate.new(engine:, raw_template:)`.

[Back to Top](#)

### Template Engines

Each template defines an optional `#engine` property. When generating the file contents, the template engine is matched against the definitions in `Cuprum::Cli::Files::Engines`. If a matching definition is found, that engine is used to generate the file contents using the raw template and the [generator parameters](#generator-parameters).

```ruby
engine = Cuprum::Cli::Files::Engines.fetch(Cuprum::Cli::Files::Engines::ERB)
engine
#=> Cuprum::Cli::Files::Engines::RenderErb
engine.call(raw_template, **parameters)
#=> The generated contents of the file.
```

To use a custom engine, define a subclass of `Cuprum::Command` with a `#process` method that takes a `raw_template` String argument and any keywords. The `#process` method must return either the generated `String` contents or a failing `Cuprum::Result` with a `Cuprum::Error` explaining the failure.

```ruby
class SprintfEngine < Cuprum::Command
  private

  def process(raw_template, **parameters)
    sprintf(raw_template, parameters)
  rescue KeyError => exception
    error = Cuprum::Error.new(message: exception.message)
    failure(error)
  end
end
```

Once the engine is defined, register the engine in `Cuprum::Cli::Files::Engines`:

```ruby
Cuprum::Cli::Files::Engines.register('sprintf', SprintfEngine)
```

Any subsequent generators that receive a template with `engine: 'sprintf'` will generate the file contents using the defined `SprintfEngine` command.

[Back to Top](#)

#### ERB Engine

`Cuprum::Cli` has one default engine which generates `ERB` content using the <a href="https://herb-tools.dev/" target="_blank">Herb toolchain</a>.

[Back to Top](#)

## Using Generators

The recommended way of using generators is via the [New File command](./built-in#new-file-command).

```ruby
generators = [
  MarkdownGenerator,
  YamlGenerator
]
command = Cuprum::Cli::Files::NewCommand.new(generators:)

command.call('docs/generators.md')
```

The `Files::NewCommand` automatically takes care of finding the matching generator class from its list of configured generators, initializing the generator, and calling it with any options.

However, generators can also be invoked directly using the `#call` method.

```ruby
generator = DocsGenerator.new(dry_run: true)
generator.call('docs/generators.md')
```

Either way, once a generator is called, it performs the following steps:

- The generator [filters the defined outputs](#filtering-outputs) based on the given options.
- If all outputs are filtered out, it returns a failing result. Otherwise, for each enabled output:
  - The generator determines the [output file path](#file-paths) for the output.
  - The generator reads the raw template from the [template](#templates) for the output.
  - Using the [template engine](#template-engine) defined for the template, the options, and the parameters from the file path, the generator [generates the file contents](#generating-files).
  - Finally, the generator writes the contents to the output file path.

If any of these steps fails, the generator will return [a failing Result](https://www.sleepingkingstudios.com/cuprum/results).

In addition to any [custom options](#generator-options) defined for the generator class, each generator has several standard options:

`:directories`
: If `true`, generates intermediate directories, similar to the `-p` flag for the `mkdir` utility. Defaults to `true`

`:dry_run`
: If `true`, does not generate the actual output files, but outputs to the terminal as normal. Defaults to `false`.

`:quiet`
: Suppresses non-error output to the terminal.

`:verbose`
: Displays the full contents of the generated files in the terminal. Very useful when combined with `--dry-run` to preview the file contents.

[Back to Top](#)

### Generating Files

The contents of each generated file depends on three things: the [raw template](#templates) and the [template engine](#template-engines) configured for the output, and the [generator parameters](#generator-parameters). When the generator is called, the raw template and the parameters are passed to the engine, and the resulting text will be used as the contents of the generated file.

`Cuprum::Cli` has one default engine which [generates ERB content](#erb-engine) using the <a href="https://herb-tools.dev/" target="_blank">Herb toolchain</a>. All other templates are treated as plain text, and the exact contents of the template will be used as the contents of the generated file.

[Back to Top](#)

#### Generator Parameters

When generating a file, both the generated file name (via the [defined output](#generator-outputs)) and the file contents (via the [template engine](#template-engines)) can accept parameterized values. By default, these values are filled from the following sources:

- The parameters parsed from the [file path](#file-path).
- The [options](#generator-options) passed to the generator.

To override this behavior, define a generator subclass and override the `#parameters` method. For example, to make the current timestamp available when generating the file, you could use the following:

```ruby
class GeneratorWithTimestamp < Cuprum::Cli::Files::Generator
  # Define outputs here.

  def parameters
    super.merge(timestamp: Time.now.utc.iso8601)
  end
end
```

[Back to Top](#)

#### Custom Templates

The template used for a given output can be customized by defining a matching option. If the output does not have a `:key`, the corresponding option should be named `:template`, while the option for a keyed output should be the key followed by `_template`. For example, the option for the `:ruby` output would be defined using `option :ruby_template`.

Once the option is defined, you can then pass a custom template path to the generator, either in the generator options (as `template: 'path/to/template.txt.erb'`) or on the command line (as `--template=path/to/template.txt.erb`). This template path will be used when generating the corresponding output file instead of whatever template was originally defined for that output.

If the output does not define a [template](#output-templates), the generator will need to be provided a template option for that output. In such cases, use `required: true` for that option.

[Back to Top](#)

### Filtering Outputs

In addition to customizing templates, you can use options to determine which outputs are actually generated when the generator is called. To do so, define an option with `type: :boolean` whose name matches the `:key` of the output. For example, the option to disable the `:ruby` output would be defined as `option :ruby, type: :boolean, default: true`. You can instead pass `default: false`, indicating that the output should be skipped unless specifically requested by the user.

Once the option is defined, you can then pass a `true` or `false` value to the generator, either in the generator options (as `ruby: false`) or on the command line (as `--ruby` to enable the output, or `--skip-ruby` to disable it). If an output is disabled, the generator will not evaluate the output name, generate the file contents, or write that output to the file system.

[Back to Top](#)

## Built-In Generators

`Cuprum::Cli` defines several built-in generators for defining Ruby and RSpec source files.

- [Ruby Generator](#ruby-generator)
- [RSpec Generator](#rspec-generator)

[Back to Top](#)

### Ruby Generator

The `RubyGenerator` creates a Ruby source file at the given file path, with contents that define a new class or module whose name matches the file path. Additionally, it creates a spec file in the `spec` directory that describes the newly created class. For the input path `lib/space/rocket.rb` and option `--parent-class=Vehicle`, the generator creates the following files.

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

`RubyGenerator` defines the following options:

`:parent_class`
: If given, instead of defining a `Module`, the generated Ruby file defines a `Class` that inherits from the given parent class.

`:rspec`
: Pass `rspec: false` to disable generating the RSpec file (on the command line, `--skip-rspec`).

`:rspec_template`
: The path to the template used to generate the RSpec file.

`:ruby`
: Pass `ruby: false` to disable generating the Ruby file (on the command line, `--skip-ruby`).

`:ruby_template`
: The path to the template used to generate the Ruby file.

[Back to Top](#)

### RSpec Generator

The `RSpecGenerator` creates an RSpec spec file at the given file path, with contents that describe a class or module whose name matches the file path. For the input path `spec/space/rocket_spec.rb`, the generator creates the following files:

In `spec/space/rocket_spec.rb`:

```ruby
# frozen_string_literal: true

require 'space/rocket'

RSpec.describe Space::Rocket do
  pending
end
```

[Back to Top](#)
