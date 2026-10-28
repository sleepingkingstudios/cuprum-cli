---
breadcrumbs:
- name: Documentation
  path: "/"
- name: Versions
  path: "/versions"
- name: Version 0.2
  path: "/versions/0.2"
version: '0.2'
---

# File Generation

In addition to the [New File Command](../commands/built-in#new-file-command), `Cuprum::Cli` provides tools for custom file generation using a flexible template system.

- **[Engines](#engines)** are used to process raw templates and parameters into finalized text.
- **[Templates](#templates)** generate output text from a given source and parameters.
- **[Generators](#generators)** are used to write generated files to the file system. Each generator defines one or more outputs with corresponding template, as well as configuration options and an optional file matcher.

## Contents

- [Engines](#engines)
  - [Registering Engines](#registering-engines)
  - [ERB Engine](#erb-engine)
- [Templates](#templates)
  - [Basic Templates](#basic-templates)
  - [File Templates](#file-templates)
  - [String Templates](#string-templates)
  - [Custom Templates](#custom-templates)
- [Generators](#generators)
  - [Generator Outputs](#generator-outputs)
  - [Generator Options](#generator-options)
  - [Path Parameters](#path-parameters)
  - [Generator Matching](#generator-matching)
  - [Filtering Outputs](#filtering-outputs)

## Engines

`Cuprum::Cli` uses **engines** to process raw [templates](#templates) and parameters into finalized text. Internally, each engine is a <a href="https://www.sleepingkingstudios.com/cuprum/commands/" target="_blank">Cuprum command</a> that takes a *template* argument and *parameters* keywords and returns a `Cuprum::Result` with the output text.

```ruby
template   = <<~HTML
  <h1>Greetings, <%= name %>!</h1>
HTML
parameters = { name: 'starfighter' }
engine     = Cuprum::Cli::Files::Engines::RenderErb.new
result     = engine.call(template, **parameters)

result.class
#=> Cuprum::Result
result.success?
#=> true
result.value
#=> "<h1>Greetings, starfighter!</h1>"
```

In the above example, we use the [ERB Engine](#erb-engine) to generate our output text. When we call the engine, we pass it two values. The **template** is a `String` containing the base template, and its contents must match the syntax expected by the engine (such as the `<%= %>` ERB syntax when calling the ERB engine). The **parameters** are a `Hash` with `Symbol` keys that are used to fill in dynamic content in the template. Above, we can see that the `name: 'starfighter'` parameter was used to fill in the template.

Calling `engine.call()` returns an instance of `Cuprum::Result`. You can use the `result.success?` and `result.failure?` methods to check whether the engine was called successfully. If the engine was able to generate valid output, then `result.success?` will return `true`, and you can use the `result.value` method to extract the output text.

Conversely, if engine was unable to generate the output, then `result.success?` will return `false`, and you can check the reason for the failure by calling `result.error`. For example, the template value might not have the correct syntax for the engine, or there may be missing parameters required to generate the output.

For a full list of available methods, see the [Reference documentation](../reference/cuprum/cli/files/engines).

[Back to Top](#)

### Registering Engines

To use an engine automatically in a [template](#templates), the engine must be registered by file extension. By default, only the [ERB Engine](#erb-engine) is registered. To register additional engines, use the `Engines.register()` class method:

```ruby
# Register engine for files with a .liquid suffix. For example, the template
# file `invoice.txt.liquid` will be processed using the RenderLiquid engine and
# output file `invoice.txt`.
Cuprum::Cli::Files::Engines.register('liquid', RenderLiquid)

Cuprum::Cli::Files::Engines.fetch('liquid')
#=> RenderLiquid
```

You can override previously registered engines by calling `register` again. For example, you could set a custom engine to handle `.erb` files for your application by defining an engine command and registering it using `register('erb', CustomEngine)`.

[Back to Top](#)

### ERB Engine

The built-in ERB engine generates output using the <a href="https://github.com/ruby/erb" target="_blank">ERB (Embedded Ruby)</a> template processor. Internally, it uses the <a href="https://herb-tools.dev/" target="_blank">Herb</a> gem to generate output text.

```ruby
template   = <<~HTML
  <h1>Greetings, <%= name %>!</h1>
HTML
parameters = { name: 'starfighter' }
engine     = Cuprum::Cli::Files::Engines::RenderErb.new
result     = engine.call(template, **parameters)

result.value
#=> "<h1>Greetings, starfighter!</h1>"
```

[Back to Top](#)

## Templates

`Cuprum::Cli` uses **templates** to generate output using a specific engine, base text, and rendering logic. Each template has three parts:

- The **data** used to resolve the base text for the template. For a [file template](#file-templates), this is the path to the template file; for a [string template](#string-templates), this is the raw template value; and so on.
- The **rendering logic** used to resolve the base text for the template.
- An optional **[engine](#engines)** that combines the rendered text and the **parameters** passed to the template.

Templates are designed for use in [generators](#generators), but you can also invoke them as standalone objects. Internally, a template is a subclass of `Data`, but follows the same interface as a <a href="https://www.sleepingkingstudios.com/cuprum/commands/" target="_blank">Cuprum command</a>: it defines a `#call(**parameters)` method and returns a `Cuprum::Result`.

```ruby
raw_template = <<~HTML
  <h1>Greetings, <%= name %>!</h1>
HTML
template = Cuprum::Cli::Files::Templates::StringTemplate.new(
  raw_template:,
  engine:       Cuprum::Cli::Files::Engines::ERB
)

result = template.call(name: 'starfighter')
result.success?
#=> true
result.value #=> "<h1>Greetings, starfighter!</h1>"

result = template.call
result.success?
#=> false
result.error.message
#=> 'missing parameter "starfighter" for .erb template'
```

In our above example, we define the template with an HTML content string and specify that the template should use the ERB engine to process the content and parameters. We then render the template using `template.call` and pass it the parameters needed to fill in the contents - in this case, the `name` parameter used in the ERB output.

The template returns an instance of `Cuprum::Result`. If the template rendered correctly, then `result.success?` will be `true`, and we can retrieve the rendered text using `result.value`. However, if there were any errors during the rendering process, then `result.success?` will return `false`, and we can inspect `result.error` to see what went wrong.

> **Danger**
>
> Beware of defining or rendering templates using untrusted user input - this may result in **arbitrary code execution** using some engines, such as ERB. If you have to render output based on user input, follow these rules to reduce your risk:
>
> 1. Do not allow untrusted users to set the **contents** of the rendered template - the base output that is rendered by the engine.
> 2. Do not define templates that call methods on input parameters - always handle any processing *before* rendering the template.
> 3. If the template results can be treated as code (including rendering as HTML or writing to the file system), **sanitize** the results before using the output of the template.

For a full list of available methods, see the [Reference documentation](../reference/cuprum/cli/files/template).

[Back to Top](#)

### Basic Templates

A `BasicTemplate` is the most flexible template type. Instead of initializing the template with a pre-defined output, the contents are passed as a parameter, allowing for more dynamic output than other template types.

```ruby
template = Cuprum::Cli::Templates::BasicTemplate.new(
  engine: Cuprum::Cli::Files::Engines::ERB
)

result = template.call(contents: 'Greetings, starfighter!')
result.value
#=> "Greetings, starfighter!"

result = template.call(contents: "Greetings, <%= name %>!", name: 'programs')
result.value
#=> "Greetings, programs!"
```

Because basic templates take their contents as a parameter, rather than on initialization, they are the most flexible type of template, but provide limited value in and of themselves. Use a `BasicTemplate` when you need to process dynamic text using an engine.

[Back to Top](#)

### File Templates

A `FileTemplate` reads its contents from the local filesystem. It must be initialized with a `file_path` parameter, which is the path to the template file to be read. The file will be read when the template is rendered; if the file cannot be read, the template will return a failing `Cuprum::Result` with an error.

File templates can automatically infer the engine to use based on the file extension. For example, a file with extension `.html.erb` will render using the ERB engine. To disable this behavior, pass an explicit `engine: nil` parameter to the constructor.

You can also pass a [FileSystem](../commands/dependencies#filesystem) dependency to the template, e.g. a mock file system for testing.

```html
<!-- In path/to/template.html.erb -->
<h1>Greetings, <%= name %>!</h1>
```

```ruby
template = Cuprum::Cli::Templates::FileTemplate.new(
  file_path: './path/to/template.html.erb'
)

result = template.call(name: 'starfighter')
result.value
#=> "<h1>Greetings, starfighter!</h1>"
```

When called, the template reads the local filesystem for the contents of the file path, and then calls the configured engine (if any) with the file contents and any given parameters.

[Back to Top](#)

### String Templates

A `StringTemplate` is initialized with a raw template `String` that is used as the contents when the template is rendered. Unlike a [Basic template](#basic-template), the contents are static once the template is defined and will be the same each time the template is rendered, although the output may differ based on the parameters passed to the template.

```ruby
raw_template = <<~HTML
  <h1>Greetings, <%= name %>!</h1>
HTML
template = Cuprum::Cli::Files::Templates::StringTemplate.new(
  raw_template:,
  engine:       Cuprum::Cli::Files::Engines::ERB
)

result = template.call(name: 'starfighter')
result.value
#=> "<h1>Greetings, starfighter!</h1>"
```

Using `<<~` heredocs is useful for defining templates, but for longer template contents, a [file template](#file-templates) may be a better choice.

> **String Templates And Basic Templates**
>
> The `StringTemplate` and `BasicTemplate` classes are superficially similar - both render a `String` using the given engine and parameters. However, a `StringTemplate` sets its contents when the template is **defined**, while the `BasicTemplate` gets its contents from the parameters when the template is **rendered**.

[Back to Top](#)

### Custom Templates

You can also define custom templates. The most common reason to create a custom template is to load the template contents from a different source.

```ruby
ExternalTemplate = Cuprum::Cli::Files::Template.define(:http_client, :url) do
  private

  def raw_value
    http_client.get(url)
  rescue StandardError => exception
    error = Cuprum::Error.new(
      message: "unable to load template from #{url} - #{exception.message}"
    )
    failure(error)
  end

  def template_name = url
end

template = ExternalTemplate.new(http_client:, url: 'www.example.com')
template.url
#=> 'www.example.com'
result   = template.call
result.value
#=> The data returned by GET www.example.com
```

To create a custom template, we use the `Template.define` class method, which returns a custom `Data` subclass. Our template needs an HTTP client and the URL of the template, so we pass `:http_client` and `:url` to `.define` so our Data subclass has those members.

In the block, we define our custom logic. The `#raw_value` helper is what determines the contents of the template, prior to applying the engine. We also set the `#template_name` helper, which is used in some error cases to provide additional information when a template is unable to render.

Custom templates can also be used to modify the retrieved contents, either before or after the engine is called. To do so, we need to modify the `#process` method directly:

```ruby
LoudTemplate = Cuprum::Cli::Files::StringTemplate.define do
  private

  def process(**parameters)
    # Retrieve the raw template contents.
    template = step { raw_value }

    # Apply the engine, if any.
    output   = step { apply_engine(template, **parameters) }

    output.upcase
  end
end

raw_template = <<~HTML
  <h1>Greetings, <%= name %>!</h1>
HTML
template = LoudTemplate.new(
  raw_template:,
  engine:       Cuprum::Cli::Files::Engines::ERB
)
result = template.call(name: 'starfighter')
result.value
#=> "<H1>GREETINGS, STARFIGHTER!</H1>"
```

In the above example, we define a custom subclass of `StringTemplate` and redefine the `#process` method to do three things:

- We call `raw_value` to retrieve the raw template contents.
- We call `apply_engine` to generate the output from the contents and the given parameters.
- Finally, we modify the output and return it using `output.upcase`.

We could also modify the contents *before* applying the engine by changing the value passed to `apply_engine`.

> A note on the `step` function: this is a feature defined in the <a href="https://www.sleepingkingstudios.com/cuprum" target="_blank">Cuprum</a> gem. The `#step` function evaluates the block and checks the returned value.
>
> - If the value is not a `Cuprum::Result`, it returns the value.
> - If it is a **passing** `Cuprum::Result`, then `step` returns `result.value`.
> - If it is a **failing** `Cuprum::Result`, then it halts the execution and the parent context (in this case the `template.call` invocation) immediately returns the failing result.
>
> For more information, see the <a href="https://www.sleepingkingstudios.com/cuprum/commands/steps" target="_blank">Cuprum documentation</a>.

[Back to Top](#)

## Generators

Generators are used to write generated files to the file system. Each generator defines one or more [outputs](#generator-outputs) with corresponding [template](#templates), as well as configuration [options](#generator-options) and an optional [file matcher](#generator-matching).

For example, you can define a generator that, when given the path for a Ruby source file, generates the Ruby file and the corresponding RSpec test file.

```ruby
class RubyGenerator < Cuprum::Cli::Files::Generator
  match_file(/\.rb\z/)

  option :parent_class

  option :ruby,  type: :boolean, default: true
  option :rspec, type: :boolean, default: true, aliases: %i[spec]

  option :ruby_template
  option :rspec_template

  output '%<file_path>s',
    key:      :ruby,
    template: 'templates/ruby.rb.erb'

  output File.join('spec', '%<relative_path>s', '%<short_name>s_spec.rb'),
    key:      :rspec,
    template: 'templates/rspec.rb.erb'
end
```

We start out by specifying a [match statement](#generator-matching), which indicates that the generator can match file paths ending with an `.rb` extension.

Next, we define a set of [options](#generator-options), which are used for generating the files. The `:ruby` and `:rspec` options are used when [determining which output files to generate](#filtering-outputs), while the `:ruby_template` and `:rspec_template` options allow the user to override the template used to create those files. The `:parent_class` option is used as a parameter by the templates to generate the source files. If the generator is called with a [file path](#path-parameters), the generator automatically includes additional parameters such as `:file_path`, `:relative_path`, and `:short_name`.

Finally, we declare the generator [outputs](#generator-outputs), which are the files that will be written when the generator is called.

A generator can be [passed to the New File Command](../commands/built-in#new-file-command), or it can be called directly using the `#call` method.

```ruby
file_path = 'lib/space/rocket.rb'
result    = RubyGenerator.new.call(file_path)
result.success?
#=> true
result.value
#=> ['lib/space/rocket.rb', 'spec/space/rocket_spec.rb']

File.exist?('lib/space/rocket.rb')
#=> true
File.exist?('spec/space/rocket_spec.rb')
#=> true
```

For a full list of available methods, see the [Reference documentation](../reference/cuprum/cli/files/generator).

[Back to Top](#)

### Generator Outputs

Generator outputs are defined by calling the `.output` class method.

```ruby
output '%<file_path>s',
  key:      :ruby,
  template: 'templates/ruby.rb.erb'
```

Each output specifies three things:

- A **file path**, which is the path the output file can be written to. The file path can be parameterized, using the values from the generator [options](#generator-options) or parameters derived from the [file path](#path-parameters).
- A **template**, which is used to determine the contents of the output file. The template can be an instance of a [template](#templates) or the path to a template file. When the template is evaluated, it is passed the generator options and any parameters derived from the input path.
- An optional **key**, which is used when [determining which output files to generate](#filtering-outputs). The key must be unique for that generator. If there is no key specified, the key is set to `:default`.

It is possible to override the configured template for an output by specifying a matching [option](#generator-options). For an unnamed or `:default` output, define `option :template`; for an output with a specified key, define an option with the key followed by `_template`. In the above example, for the output with `key: :ruby`, the option name would be `:ruby_template`. Then, pass a corresponding template file path as that option when the generator is called:

```ruby
RubyGenerator.new.call(ruby_template: 'custom_templates/ruby.rb.erb')
```

The output file will then be generated using the template at `'custom_templates/ruby.rb.erb'`.

[Back to Top](#)

### Generator Options

Generator options are defined using the same DSL as [command options](../commands/#command-options), using the `.option` class method.

```ruby
option :rspec, type: :boolean, default: true, aliases: %i[spec]
```

In addition to the option name, which must be a non-empty `String` or `Symbol`, the `.option` class method supports the following options:

:aliases
: Aliases for the option when parsing options from the command line.

:default
: The default value for the option. If given and the value of the option is `nil`, sets the option value to the default value. Can either be any object or a `Proc` used to set the value when the command is called.

:required
: If true, an exception is raised when the command is called if the option value is not present. Defaults to `false`.

:type
: The expected type of the option value as a `Class` or class name. If given, raises an exception if the option value is not an instance of the type. Defaults to :string.

The generator option values are combined with the [parameters from the file path](#path-parameters) (if any) when creating the path and contents for each [output file](#generator-outputs). Options can also be used to [customize output templates](#generator-outputs) and to [filter which outputs are generated](#filtering-outputs).

[Back to Top](#)

#### Default Options

In addition to any user-defined options, each generator also has access to the following option flags:

- If the `:directories` flag is set to `true`, then the generator will make any missing intermediate directories when writing files. For example, for an output file at `lib/space/rocket.rb`, the generator will create the `lib` and `lib/space` directories if they do not already exist. Defaults to `true`.
- If the `:dry_run` flag is set to `true`, then the generator will not make any changes to the file system. Defaults to `false`.
- If the `:quiet` flag is set to `true`, then the generator will only write minimal output to STDOUT. Error messages are not affected. Defaults to `false`.
- If the `:verbose` flag is set to `true`, then the generator will report the generated file contents to STDOUT. Defaults to `false`.

[Back to Top](#)

### Path Parameters

If the generator is passed a file path, the generator will parse the file path for a number of parameters that are useful for defining new files relative to the input file path. The following examples use an input file path of `"lib/path/to/file.rb"`:

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

Each of these parameters can be used when generating [output files](#generator-outputs), both in the output file path and in the contents.

[Back to Top](#)

### Generator Matching

Generators define a mechanism for matching valid file paths for the generator. Use the `.match_file` class method to declare a matching pattern, and the `.match?` class method to check if a generator matches the file path:

```ruby
class YamlGenerator < Cuprum::Cli::Files::Generator
  match_file(/\.yaml\z/)

  match_file(/\.yml\z/)
end

YamlGenerator.match?('docs/index.yaml')
#=> true
YamlGenerator.match?('docs/index.yml')
#=> true
YamlGenerator.match?('docs/index.md')
#=> false
```

Generator matching is used in the [New File Command](../commands/built-in#new-file-command) to select the generator used to output a requested file.

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

[Back to Top](#)

### Filtering Outputs

Generators with [multiple output files](#generator-outputs) can configure which files to output each time the generator is called. To do so, define an [option](#generator-options) with the same name as the output's `:key` (or `:default`, if the output does not set a `:key`). Then, when the generator is called, set the value of that option to `false`. The corresponding output file will not be generated.

```ruby
result = RubyGenerator.new.call('lib/space/rocket.rb')
result.value
#=> ['lib/space/rocket.rb', 'spec/space/rocket_spec.rb']

File.exist?('lib/space/rocket.rb')
#=> true
File.exist?('spec/space/rocket_spec.rb')
#=> true

result = RubyGenerator.new.call('lib/space/satellite.rb', rspec: false)
result.value
#=> ['lib/space/satellite.rb']

File.exist?('lib/space/satellite.rb')
#=> true
File.exist?('spec/space/satellite_spec.rb')
#=> false
```

In the above example, we set the `:rspec` option to `false` when we generate the output files for `'lib/space/satellite.rb'`. This disables the `RSpec` file output, and its not written to the file system.

[Back to Top](#)
