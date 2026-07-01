---
breadcrumbs:
  - name: Documentation
    path: '/'
---

# Commands

A `Cuprum::Cli::Command` defines an action or sequence of actions that can be called from the command line. Each command defines the [arguments](#arguments), [options](#options), and [dependencies](#dependencies), as well as the business logic that is evaluated when the command is called.

Internally, a `Cuprum::Cli::Command` leverages <a href="https://www.sleepingkingstudios.com/cuprum/commands/" target="_blank">Cuprum commands</a>, which provides simple but powerful tools for managing success and failure cases.

## Contents

- [Defining Commands](#defining-commands)
- [Success And Failure](#success-and-failure)
  - [Using Steps](#using-steps)
  - [Custom Errors](#custom-errors)
- [Command Arguments](#command-arguments)
- [Command Options](#command-options)
- [Using Dependencies](#using-dependencies)

### See Also

- [Command Dependencies]({{site.baseurl}}/commands/dependencies)
  - [FileSystem]({{site.baseurl}}/commands/dependencies#filesystem)
  - [StandardIo]({{site.baseurl}}/commands/dependencies#standardio)
  - [SystemCommand]({{site.baseurl}}/commands/dependencies#systemcommand)
- [Built-In Commands]({{site.baseurl}}/commands/built-in)
  - [CI Commands]({{site.baseurl}}/commands/built-in#ci-commands)
  - [File Commands]({{site.baseurl}}/commands/built-in#file-commands)

## Defining Commands

At its base, a `Command` is a Ruby class that inherits from `Cuprum::Cli::Command`. The core logic of the command is defined in the `#process` method, which is `private` by convention and does not take any parameters.

```ruby
require 'cuprum/cli/command'

class PingCommand < Cuprum::Cli::Command
  private

  def process
    response = `ping -c5 -i0.1 -q www.example.com`
    status   = $?.to_i

    return if status.zero?

    error = Cuprum::Error.new(message: response)
    failure(error)
  end
end
```

In the above example, we define a command to test a remote service using the `ping` system command.

When the command is called, `#process` will perform a system call using <code>Kernel#&grave;</code>. If the system call is successful (with a status of `0`), then the command will return a successful `Result`. Otherwise, it generates an `Error` with the system call output and returns the error in a failing `Result`.

We can test our new command in a Ruby console using the `#call` method, which is automatically defined by `Cuprum::Cli::Command`.

```ruby
result = PingCommand.new.call
result.class
#=> Cuprum::Result
result.success?
#=> true

# For testing purposes, run the command with internet access disabled.
result = PingCommand.new.call
result.success?
#=> false
result.error
#=> an instance of Cuprum::Error
result.error.message
#=> "ping: cannot resolve www.example.com: Unknown host"
```

When we call our `PingCommand` using a third-party integration, the integration code will examine the `Result` returned by the command and decide how to present that information to the user. For more information on `Cuprum::Result`, see the <a href="https://www.sleepingkingstudios.com/cuprum/results" target="_blank">Cuprum documentation</a>.

[Back to Top](#)

## Success And Failure

As you can see, CLI commands need to be able to handle failures - invalid user inputs or data, network failures, and so on. In our `PingCommand`, we can check for success or failure at the end, without interrupting our logic. That's not always the case.

Consider a command that reads a file, modifies the contents, and then writes the file to a new location. There are a number of ways such a command might be unable to continue. The input file might not exist, might be a directory, or the current user might not have read permissions. The file contents might be in an unexpected format, or not match the business logic. Finally, the output directory may not exist or may not be writeable.

[Back to Top](#)

### Using Steps

We can check after each step in our logic to verify that there are no issues, but that's a lot of boilerplate code. Fortunately, `Cuprum` provides <a href="https://www.sleepingkingstudios.com/cuprum/commands/steps" target="_blank">a powerful tool</a> for handling mid-process errors - the `step` method. It takes a block and checks the value returned by the block. If the returned value is any non-`Result` object, it returns that value. If the returned value is a passing `Result`, it unpacks the `Result` by returning `result.value`. Finally, if the returned value is a failing `Result`, it bypasses the rest of the `#process` method and immediately returns the failing `Result`.

This is known as Railway-oriented programming, and it allows us to skip those manual status checks after each step. Instead, we can wrap the logic in a `step` call and trust `Cuprum` to halt execution immediately on a failure. In practice, it looks something like this:

```ruby
class CopyAndModifyFileCommand < Cuprum::Cli::Command
  private

  def modify_contents(contents)
    # ...
  end

  def process
    contents = step { read_file }

    contents = step { modify_contents(contents) }

    write_file(contents)
  end

  def read_file
    # ...
  end

  def write_file(contents)
    # ...
end
```

Inside each of our methods, we need to return a failing `Result` if that step is a failure. This can be be in response to an exception:

```ruby
def read_file
  # ...
rescue SystemCallError => exception
  error = Cuprum::Error.new(message: exception.message)

  failure(error)
end
```

We define a `Cuprum::Error` to explain the reason for the failure, and then use the `failure(error)` helper to quickly generate a failing `Cuprum::Result`.

Where possible, it's more efficient to use a simple boolean check to avoid allocating an `Exception` and backtrace.

```ruby
def modify_contents(contents)
  unless valid_contents?(contents)
    error = "File contents are not valid"

    return failure(error)
  end

  # ...
end
```

We can even take advantage of the fact that `step` calls interrupt the flow and simplify our `#modify_contents` method further:

```ruby
def modify_contents(contents)
  step { validate_contents(contents) }

  # ...
end
```

If our new `#validate_contents` method returns a failing `Result`, then not only will our command skip the rest of `#modify_contents`, it will also skip the remaining methods in `#process` and immediately return the failing result.

For more information on the `#step` method, including how to set up nested `step` contexts, see the <a href="https://www.sleepingkingstudios.com/cuprum/commands/steps" target="_blank">Cuprum documentation</a>.

[Back to Top](#)

### Custom Errors

Let's return to our `PingCommand`. On a failure, we are returning a generic `Cuprum::Error` with an error message. For a command we call directly from the CLI, this is probably fine. But what happens when we want to call it from another command - say, to verify that an API is available before generating a report? What if we want to handle multiple error cases differently? We certainly don't want to be parsing the error message to find out what happened - not only is that a pain, it's going to be very fragile.

The solution `Cuprum` provides for this is defining custom `Error` classes. Here is what that might look like for our `PingCommand`:

```ruby
class PingCommand::ServiceNotAvailableError < Cuprum::Error
  TYPE = 'ping_command.service_not_available'

  def initialize(service:, details: nil)
    message = "unable to resolve service #{service.inspect}"
    message = "#{message} - #{details}" if details

    super(details:, message:, service:)

    @service = service
  end

  attr_reader :service
end
```

Each error have three parts:

- The error `#message` provides a user-readable representation of the error.
- The error `type` provides a unique identifier for the error, useful for code that handles multiple possible error types.
- Finally, errors can have additional properties that provide additional information about the error. In the above example, the `#service` property identifies the service that was not reachable.

Using bare `Cuprum::Error`s is fine for a small script, but for a larger application or reusable library, I recommend writing custom errors for each case - it can save a lot of time when debugging issues or tracking failures. Likewise, although adding an inline error class for the command works for a small project, I recommend defining a dedicated `errors` directory, particularly when your application has errors that might be encountered in more than one code path.

For more information on `Cuprum` errors, see the <a href="https://www.sleepingkingstudios.com/cuprum/errors" target="_blank">Cuprum documentation</a>.

[Back to Top](#)

### Command Arguments

Our `PingCommand` works - but it would be a lot more useful if we could specify which service we wanted to check. `Cuprum::Cli` provides two ways to pass parameters to a command - positional arguments and [options](#command-options). To pass a service into our `PingCommand`, we'll define a positional argument.

> Why a positional argument and not an option? Positional arguments don't require an option name, so they're best suited for parameters that are the primary input for the command, such as a file name.

Let's go ahead and update our command.

```ruby
class PingCommand < Cuprum::Cli::Command
  argument :service_url,
    default:     'www.example.com',
    description: 'The URL of the remote service',
    type:        String

  private

  def process
    response = `ping -c5 -i0.1 -q #{service_url}`
    status   = $?.to_i

    return if status.zero?

    error = Cuprum::Error.new(message: response)
    failure(error)
  end
end

result = PingCommand.new.call('https://github.com/')
result.success?
#=> true
```

We declare our argument using the `.argument` class method. `Cuprum::Cli` handles the rest - declaring the `#service_url` reader method and extracting the value from the arguments passed to `#call`. In our `#process` method, we then can reference the `#service_url` method to ping a different service.

In addition to the argument name, which must be a non-empty `String` or `Symbol`, the `.argument` class method supports the following options:

:default
: The default value for the argument. If given and the value of the argument is `nil`, sets the argument value to the default value. Can either be any object or a `Proc` used to set the value when the command is called.

:define_method
: If true, defines a public reader method for the command that returns the value of the argument. Defaults to `true` for non-boolean arguments and `false` for boolean arguments.

:define_predicate
: If true, defines a public predicate method for the command that `true` if the value is present, or `false` if the value is `nil` or empty. Defaults to `true` for boolean arguments and `false` for all other argument types.

:description
: A short, human-readable description of the argument.

:required
: If true, an exception is raised when the command is called if the argument value is not present. Defaults to `false`.

:type
: The expected type of the argument value as a `Class` or class name. If given, raises an exception if the argument value is not an instance of the type. Defaults to :string.

:variadic
: If true, the argument is variadic and represents an array of arguments provided to the command. Defaults to `false`.

You can define multiple arguments for a command, and `Cuprum::Cli` will apply those arguments in the order they are defined. For example, if we define a `CalculateDistanceCommand` with arguments `:x`, `:y`, and `:z` in that order, and we call the command with arguments `2`, `3`, and `5`, then the `#x` value will be set to `2`, the `#y` value will be set to `3`, and so on.

`Cuprum::Cli` also has support for variadic arguments, either by declaring them via the `.arguments` class method or passing `variadic: true` to `.argument`. A variadic argument will take any number of command line arguments. If a command has both regular and variadic arguments, `Cuprum::Cli` will fill the regular arguments first, and the variadic argument with any remaining values.

Generally speaking, a command should have at most one positional argument, or accept any number of identical arguments (such as a list of file names). If your command needs more than one type of positional argument, it may be worth changing it to use [options](#command-options) instead.

[Back to Top](#)

### Command Options

We can specify which service we want to check, but our `PingCommand` still has a lot of hard-coded values. Let's make it more configurable by defining options for the command.

```ruby
class PingCommand < Cuprum::Cli::Command
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

  def process
    response = `ping -c#{max_count} -i#{interval} -q #{service_url}`
    status   = $?.to_i

    return if status.zero?

    error = Cuprum::Error.new(message: response)
    failure(error)
  end
end

result = PingCommand.new.call('https://github.com/', max_count: 10, interval: 0.5)
result.success?
#=> true
```

We define our options using the `.option` class method. As with arguments, `Cuprum::Cli` handles the rest - declaring the `#interval` and `#max_count` reader methods and extracting the value from the options passed to `#call`.

In addition to the option name, which must be a non-empty `String` or `Symbol`, the `.option` class method supports the following options:

:aliases
: Aliases for the option when parsing options from the command line.

default
: The default value for the option. If given and the value of the option is `nil`, sets the option value to the default value. Can either be any object or a `Proc` used to set the value when the command is called.

:define_method
: If true, defines a public reader method for the command that returns the value of the option. Defaults to `true` for non-boolean arguments and `false` for boolean arguments.

:define_predicate
: If true, defines a public predicate method for the command that `true` if the value is present, or `false` if the value is `nil` or empty. Defaults to `true` for boolean arguments and `false` for all other option types.

:description
: A short, human-readable description of the option.

:required
: If true, an exception is raised when the command is called if the option value is not present. Defaults to `false`.

:type
: The expected type of the option value as a `Class` or class name. If given, raises an exception if the option value is not an instance of the type. Defaults to :string.

[Back to Top](#)

## Using Dependencies

Our `PingCommand` is now pretty flexible. It is not, however, very readable - that magic <code>Kernel#&grave;</code> call is an eyesore. The command is also going to be hard to test.

To make developing and testing commands easier, `Cuprum::Cli` defines [Command Dependencies]({{site.baseurl}}/commands/dependencies), modules which wrap external behavior. We can make the `PingCommand` much more readable by using the [SystemCommand dependency]({{site.baseurl}}/commands/dependencies#systemcommand).

To add a dependency to a `Cuprum::Cli::Command`, we use the `.dependency` class method.

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

Here, we can see that after declaring the `system_command` dependency, we can then access it inside our `#process` method. Using the `system_command` has simplified our logic considerably, even though we still have to manually generate our options (since the `ping` command uses a non-standard options format). It will also make testing our command much easier by using a [dependency mock]({{site.baseurl}}/commands/dependencies#mock-dependencies).

For more information on command dependencies, see the [dependency documentation]({{site.baseurl}}/commands/dependencies).

[Back to Top](#)
