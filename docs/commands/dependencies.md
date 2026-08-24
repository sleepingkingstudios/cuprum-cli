---
breadcrumbs:
  - name: Documentation
    path: '/'
  - name: Commands
    path: '/commands'
---

# Command Dependencies

To make developing and testing commands easier, `Cuprum::Cli` defines Command Dependencies, modules which wrap external behavior. Each built-in dependency wraps an external interface, such as the file system or standard IO streams.

Internally, Command Dependencies use the <a href="https://www.sleepingkingstudios.com/plumbum" target="_blank">Plumbum</a> library for dependency management.

## Contents

- [Using Dependencies](#using-dependencies)
- [Built-In Dependencies](#built-in-dependencies)
  - [Clock](#clock)
  - [FileSystem](#filesystem)
  - [StandardIo](#standardio)
  - [SystemCommand](#systemcommand)
- [Dependencies And Testing](#dependencies-and-testing)

## Using Dependencies

Before using a dependency in a [command class]({{site.base_url}}/commands), we need to declare that dependency for the command using the `.dependency(name)` class method.

```ruby
class GreetCommand < Cuprum::Cli::Command
  dependency :standard_io

  argument :name, default: 'programs'

  private

  def process
    standard_io.write_output("Greetings, #{name}!")
  end
end
```

The above code declares that the command uses the built-in [StandardIo](#standardio) dependency. Declaring the dependency then automatically defines the `#standard_io` helper method, which returns the value of that dependency in the current command instance. We can then use the methods or properties defined on the dependency to implement our business logic - in the above example, we use the `#write_output` method from `StandardIo` to display a message in the `STDOUT` stream.

> Why use dependencies instead of calling the functionality directly?
>
> Using a dependency allows us to reuse code for handling errors and edge cases instead of reimplementing the same functionality over and over. Because the dependency adds a layer of indirection, we can also inject a mock dependency to make testing our command much easier.

In addition to the built-in dependencies ([FileSystem](#filesystem), [StandardIo](#standardio), and [SystemCommand](#systemcommand)), we can also define our own [custom dependencies](#custom-dependencies).

The approach above only works when your class inherits from `Cuprum::Cli::Command`. To use a dependency in other contexts (such as a base `Cuprum::Command` that provides reusable functionality), we need to make a couple of additional steps.

```ruby
class DisplayGreeting < Cuprum::Cli::Command
  include Plumbum::Consumer
  prepend Plumbum::Parameters

  provider Cuprum::Cli::Dependencies.provider

  dependency :standard_io
end
```

Including `Plumbum::Consumer` defines the DSL for declaring providers and consumers, while `prepend`ing `Plumbum::Parameters` allows us to pass in a custom dependency value to the command (useful when [testing commands with dependencies]((#dependencies-and-testing))). We also need to use the `.provider` class method to allow our class to resolve the built-in dependencies to their default values.

For more information on Plumbum dependencies, see the <a href="https://www.sleepingkingstudios.com/plumbum" target="_blank">Plumbum documentation</a>.

[Back to Top](#)

## Built-In Dependencies

`Cuprum::Cli` defines three built-in dependencies - [FileSystem](#filesystem), [StandardIo](#standardio), and [SystemCommand](#systemcommand). Each built-in dependency wraps an external interface.

### Clock

The `Clock` dependency wraps Ruby's native time functionality. It defines the following methods:

`#get_monotonic_time`
: Returns a monotonically-increasing timestamp in seconds. Useful for measuring time elapsed between timestamps.

`#get_time` (also `#current_time`, `#now`)
: Returns the current time as a Ruby `Time` instance in the UTC timezone.

`#measure(&block)`
: Calls the block and returns the time elapsed between the start and end of the block.

[Back to Top](#)

#### Clock::Mock

A `Clock::Mock` allows setting the current time for testing purposes.

```ruby
clock = Cuprum::Cli::Clock::Mock.new(current_time: Time.parse('1982-07-09'))
clock.get_time
#=> => 1982-07-09 00:00:00
```

[Back to Top](#)

### FileSystem

The `FileSystem` dependency wraps the native file system and provides methods for reading from and writing to files and directories. It defines the following methods:

`#copy_file(source_path, destination_path, force: false) { |contents| }`
: Copies the contents of the file at `source_path` to a new file at `destination_path`. If a block is given, uses the block to transform the contents of the file.

`#create_directory(path, recursive: true)` (also `#make_directory`)
: Creates a directory at the requested path. If `recursive` is true, creates intermediate directories, like the `-p` option for `mkdir`.

`#delete_directory(path, force: false, recursive: false)` (also `#remove_directory`)
: Removes the directory at the requested path. If `recursive` is true, removes nested empty directories; if `force` is true, removes nested files and directories.

`#delete_file(path)` (also `#remove_file`)
: Removes the file at the requested path.

`#directory?(path)` (also `#directory_exists?`)
: Checks if the given path is a directory.

`#each_file(pattern, &block)`
: Iterates over the files matching the pattern and either returns an `Enumerable` over the matching file names or yields each file name to the given block.

`#file?(path)` (also `#file_exists?`)
: Checks if the given path is a file.

`#read_file(file_or_path)` (also `#read`)
: Reads the contents of the given IO object, or the file at the given path.

`#with_tempfile`
: Creates a tempfile and passes it to the block.

`#write_file(file_or_path, data)` (also `#write`)
: Writes the given contents to the IO object, or the file at the given path.

For more information, see the [FileSystem reference](../reference/cuprum/cli/dependencies/file-system/).

[Back to Top](#)

#### FileSystem::Mock

A `FileSystem::Mock` creates a simulated directory for testing commands. It defines the above methods as well as a `#files` accessor to view the current contents of the simulated directory. Directories are represented as nested `Hash`es, while files are represented as `StringIO` objects.

```ruby
files       = { 'tmp' => { 'file.txt' => 'This is a text file!' } }
file_system = Cuprum::Cli::Dependencies::FileSystem::Mock.new(files:)
file_system.read_file('tmp/file.txt')
#=> 'This is a text file!'
```

[Back to Top](#)

### StandardIo

The `StandardIo` dependency wraps the standard input, output, and error streams. It defines the following methods:

`#color(text, color)`
: Wraps the text in an ANSI color escape code.

`#read_input`
: Requests a newline-terminated string from the input stream.

`#write_error(message = nil, newline: true)`
: Writes the given message to the error stream.

`#write_output(message = nil, newline: true)`
: Writes the given message to the output stream.

For more information, see the [StandardIo reference](../reference/cuprum/cli/dependencies/standard-io/).

[Back to Top](#)

#### StandardIo::Mock

A `StandardIo::Mock` simulates the input, output, and error streams as `StringIO` objects and exposes them as `#input_stream`, `#output_stream`, and `#error_stream`. In addition, it defines a `#combined_stream` that captures any data written to either the output or error streams.

```ruby
standard_io = Cuprum::Cli::Dependencies::StandardIo::Mock.new
standard_io.write_output 'OK'
standard_io.write_error  'Oh no!'

standard_io.output_stream.string
#=> "OK\n"
standard_io.error_stream.string
#=> "Oh no!"
standard_io.combined_stream.string
#=> "OK\nOh no!\n"
```

[Back to Top](#)

### SystemCommand

The `SystemCommand` dependency is used to execute shell commands and capture the status and output. It defines the following methods:

`#capture(command,.arguments: [], environment: {}, options: {})`
: Executes the system command and returns the captured output.

`#spawn(command, arguments: [], enviroment:, options: {})`
: Spawns a process to run the system command.

Each above command returns a <a href="https://www.sleepingkingstudios.com/cuprum/results/" target="_blank">Cuprum result</a>, with a status of `:success` if the shell command exited with a passing status, or a result with a status of `:failure` if the shell command exited with a failing status.

For more information, see the [SystemCommand reference](../reference/cuprum/cli/dependencies/system-command/).

[Back to Top](#)

#### SystemCommand::Mock

A `SystemCommand::Mock` simulates shell commands by intercepting and recording outgoing commands and returning preconfigured outputs and statuses.

```ruby
captures       = { 'echo "Greetings, programs!"' => ['Greetings, programs!', '', 0] }
system_command = Cuprum::Cli::Dependencies::SystemCommand::Mock.new(captures:)

result = system_command.spawn('echo "Greetings, programs!"')
result.success?
#=> true

result = system_command.capture('echo "Greetings, programs!"')
result.success?
#=> true
result.value.output
#=> 'Greetings, programs!'
result.value.status.exitstatus
#=> 0
```

[Back to Top](#)

## Dependencies And Testing

`Cuprum::Cli` enables testing commands by injecting dependency mocks into the command. This allows you to write tests without having to worry about potentially dangerous side effects, such as file system operations or shell commands. Using mock dependencies also allows you to write assertions against the mocked dependency rather than its outputs.

Let's take a look at writing an RSpec spec for our `GreetCommand` using [a mock dependency](#standardiomock) in place of `StandardIo`.

```ruby
require 'cuprum/cli/dependencies/standard_io/mock'

RSpec.describe GreetCommand do
  subject(:command) { described_class.new(standard_io:) }

  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }

  describe '#call' do
    it 'prints a greeting to STDOUT' do
      command.call

      expect(standard_io.output_stream.string).to eq("Greetings, programs!\n")
    end

    it 'does not print to STDERR' do
      command.call

      expect(standard_io.error_stream.string).to eq('')
    end
  end
end
```

As you can see, we inject a mock in place of the `StandardIo` dependency by passing the mock to the command constructor. We can then write assertions against the error and output streams.

Using a mock also ensures that the spec won't pollute the test output with extra text; likewise, a mock for [FileSystem](#filesystemmock) prevents the test from making any changes to the actual file system, while a moc for [SystemCommand](#systemcommandmock) ensures that the test doesn't make any actual shell commands.

[Back to Top](#)
