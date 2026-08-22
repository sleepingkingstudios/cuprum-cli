# Changelog

## 0.2.0

## Commands

- Implemented support for resolving aliased options.
- Normalized option keys for variadic options.

### Built-In Commands

- Fixed directory expansion for `Ci::RSpecEachCommand`.
- Fixed `Ci::RSpecEachCommand` reporting failing specs as errored.
- Updated `Ci::RSpecEachCommand` output to report total elapsed time.
- Updated `File::NewCommand` to use generators instead of raw templates.

### Dependencies

- Implemented `Clock` dependency.
- Implemented `FileSystem#copy_file` helper.
- Improved handling of file parameters for `FileSystem::Mock`.
- Updated `FileSystem#each_file` enumerated values to match the given pattern - values will only be converted to absolute paths if the input pattern is an absolute path.
- Fixed a `FileSystem#each_file` bug when matching a template that included the root path.
- Fixed a `FileSystem::Mock` bug that would wipe existing mock directories.
- Fixed a `FileSystem::Mock` bug that did not include directories in `each_file`.

### Files

- Implemented file generators, a more robust solution for generating files or groups of files.
- Refactored `Errors::Files` to `Files::Errors`.

## Integrations

- Added `Async` integration.
- Added `Async::Commands::RSpecEachCommand`, which allows running spec files in parallel.
- Fixed error handling for `Thor` integration.
- Enabled passing variadic options through `Thor` tasks.

## 0.1.0

Initial version.

## Commands

Implemented `Cuprum::Cli::Command`

- Added support for positional arguments
- Added support for keyword options and flags

### Built-In Commands

- Implemented `Cuprum::Cli::Ci::RSpecCommand`
- Implemented `Cuprum::Cli::Ci::RSpecEachCommand`
- Implemented `Cuprum::Cli::File::NewCommand`

### Dependencies

- Implemented `Cuprum::Cli::Dependencies::FileSystem`
- Implemented `Cuprum::Cli::Dependencies::StandardIo`
- Implemented `Cuprum::Cli::Dependencies::SystemCommand`

### Registries

- Implemented `Cuprum::Cli::Registry`

## Integrations

Added `Thor` integration

- Implemented `Cuprum::Cli::Integrations::Thor::Registry`
