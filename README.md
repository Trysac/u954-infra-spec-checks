# infra-spec-checks

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/Trysac/u954-infra-spec-checks/actions/workflows/ci.yml/badge.svg)](https://github.com/Trysac/u954-infra-spec-checks/actions/workflows/ci.yml)

Declarative checks for servers and containers that verify listening ports, installed packages, running services and file modes from proc files, without a shell on the input

## Problem

Describe in two or three sentences the concrete problem this utility solves, who hits it, and what
they do today without it. Replace this paragraph when the first real feature lands.

## Install

```ruby
# Gemfile
gem "u954-infra-spec-checks"
```

Until it is published on RubyGems, point the Gemfile at a release tag:
`gem "u954-infra-spec-checks", git: "https://github.com/Trysac/u954-infra-spec-checks", tag: "v0.1.0"`. Requires Ruby 4.0 or newer. No
dependencies outside the Ruby standard library.

## Usage

```ruby
require "trysac/infra_spec_checks"

# normalize trims surrounding whitespace and lower-cases the text.
Trysac::InfraSpecChecks::Text.normalize("  Hello World ") # => "hello world"

# Blank input is rejected explicitly instead of returning an empty string.
Trysac::InfraSpecChecks::Text.normalize("   ") # raises Trysac::InfraSpecChecks::BlankInputError ("input is blank")
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) and [decisions](docs/decisions/)
- [Testing](docs/TESTING.md) and [security](docs/SECURITY.md)
- [Project record](docs/PROJECT.md) and [stack](docs/STACK.md)
- [Changelog](CHANGELOG.md) and [contributing guide](CONTRIBUTING.md)

## License

[MIT](LICENSE) (c) 2026 Miguel Gomez
