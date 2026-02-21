# Cuprum::Cli

A command-line utility powered by Cuprum.

Provides tools and utilities for defining command-line tools.

## About

### Documentation

Documentation is generated using [YARD](https://yardoc.org/), and can be generated locally using the `yard` gem.

### License

Copyright (c) 2026 Rob Smith

`Cuprum::Cli` is released under the [MIT License](https://opensource.org/licenses/MIT).

### Contribute

The canonical repository for this gem is located at https://github.com/sleepingkingstudios/cuprum-cli.

To report a bug or submit a feature request, please use the [Issue Tracker](https://github.com/sleepingkingstudios/cuprum-cli/issues).

To contribute code, please fork the repository, make the desired updates, and then provide a [Pull Request](https://github.com/sleepingkingstudios/cuprum-cli/pulls). Pull requests must include appropriate tests for consideration, and all code must be properly formatted.

### Code of Conduct

Please note that the `Cuprum::Cli` project is released with a [Contributor Code of Conduct](https://github.com/sleepingkingstudios/cuprum-cli/blob/master/CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.

### Local Development

The test suite for `Cuprum::Cli` is written using [RSpec](https://rspec.info/), with optional integration dependencies managed using [Appraisal](https://github.com/thoughtbot/appraisal).

To run the general test suite:

```bash
bundle exec rspec
```

To run the test suite including the `Thor` integration:

```bash
BUNDLER_GEMFILE=gemfiles/integrations_thor.gemfile INTEGRATION=thor bundle exec rspec
```

To run the [RuboCop](https://rubocop.org/) linter:

```bash
bundle exec rubocop
```
