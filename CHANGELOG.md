# Changelog

## 0.2.0

## Commands

- Fixed directory expansion for `Cuprum::Cli::Ci::RSpecEachCommand`.

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
