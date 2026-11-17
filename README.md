# infra-spec-checks

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/Trysac/u954-infra-spec-checks/actions/workflows/ci.yml/badge.svg)](https://github.com/Trysac/u954-infra-spec-checks/actions/workflows/ci.yml)

Declarative checks for servers and containers that verify listening ports, installed packages, running services and file modes from proc files, without a shell on the input

## Problem

Teams verify images and servers with ad hoc shell scripts whose output nobody parses reliably, and tools built on string interpolation run whatever a package name contains. Full frameworks pull many gems and need a Ruby inside the target. This gem defines checks as data, runs fixed commands through a local, Docker or fake backend with every argument validated and escaped, and parses /proc and package-manager output into typed results.

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

suite = Trysac::InfraSpecChecks.define do
  port(80).listening
  file("/etc/hostname").exists
end
report = suite.run(Trysac::InfraSpecChecks::Backends::Local.new)
puts report.to_text
exit(report.passed? ? 0 : 1)
```

## Why not Serverspec or Goss

Serverspec and Goss are the best-known alternatives. This gem builds no shell command from input, returns structured results (`Report#to_h`), and ships a fake backend so every probe can be tested without a host.

## Public API

- `Trysac::InfraSpecChecks.define { ... }` returns a `Suite`. The block is a builder over check objects; nothing is evaluated from files.
- Checks: `port(n).listening`, `package(name).installed(version: prefix)`, `service(name).running`, `file(path).exists.mode(octal).owner(user)`, `command(*argv).exit_status(n)`.
- `Suite.from_json(text)` builds the same checks from an array such as `[{"port": 80}, {"package": "nginx", "version": "1.30"}]`.
- `Suite#run(backend)` returns a `Report` with `to_h`, `to_text` and `passed?`.
- Backends: `Backends::Local.new(runner:)` runs argv arrays with Open3 (never a shell string); `Backends::Docker.new(container, runner:)` runs `docker exec` with a script built from fixed templates and escaped values; `Backends::Fake.new(responses)` maps argv arrays to `[stdout, stderr, status]` or `:timeout`.
- `CLI.run(argv, stdout:, stderr:)` returns 0 when all checks pass, 1 on a domain failure, 2 on usage, IO or parse errors. Options: `--docker CONTAINER` selects the Docker backend.
- Errors: `Trysac::InfraSpecChecks::Error` (a subclass of `ArgumentError`) carries a `code` Symbol: `:invalid_port`, `:invalid_name`, `:invalid_path`, `:invalid_mode`, `:invalid_checks`, `:input_too_large`, `:unsupported_os`, `:command_failed`, `:timeout`, `:usage`. Messages never contain more than 200 characters of input.
- Limits: names match `/\A[A-Za-z0-9][A-Za-z0-9._+:@-]{0,127}\z/`; paths are absolute, at most 4096 bytes, without NUL or newline; container names are at most 128 characters; a checks file is at most 1048576 bytes and at most 1000 checks; port must be from 1 to 65535.
- Probes: OS from `/etc/os-release` (Alpine uses `apk`, Debian and Ubuntu use `dpkg-query`, Fedora, RHEL, Rocky and AlmaLinux use `rpm`, other systems raise `:unsupported_os`); ports from `/proc/net/tcp` and `/proc/net/tcp6`; services via `systemctl is-active` when `/run/systemd/system` exists, otherwise the process name in `/proc/[0-9]*/comm`; files via `stat -c '%a %U %G %F'`.
- `Trysac::InfraSpecChecks::Text.normalize(text)` trims and lower-cases text and raises `BlankInputError` for blank input.

Security model and known limits: [docs/SECURITY.md](docs/SECURITY.md).

## Documentation

- [Architecture](docs/ARCHITECTURE.md) and [decisions](docs/decisions/)
- [Testing](docs/TESTING.md) and [security](docs/SECURITY.md)
- [Project record](docs/PROJECT.md) and [stack](docs/STACK.md)
- [Changelog](CHANGELOG.md) and [contributing guide](CONTRIBUTING.md)

## License

[MIT](LICENSE) (c) 2026 Miguel Gomez
