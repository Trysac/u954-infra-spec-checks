# Architecture

## Purpose

The gem `u954-infra-spec-checks` is a small Ruby library, using only the standard library at runtime, that defines declarative checks for servers and containers and runs them through pluggable backends. It verifies listening ports, installed packages, running services, file modes and command exit statuses.

## Shape

```text
caller code --> require "trysac/infra_spec_checks" (lib/trysac/infra_spec_checks.rb)
                    |
                    +-- module Trysac::InfraSpecChecks (lib/trysac/infra_spec_checks/)
                          +-- DSL builder and check objects (define, Suite.from_json)
                          +-- Suite#run(backend) -> Report
                          +-- Backends::Local, Backends::Docker, Backends::Fake
                          |     +-- Runner: call(argv, timeout:) -> [stdout, stderr, status]
                          +-- probes: OS detection, /proc parsing, package and stat output parsing
                          +-- CLI.run(argv, stdout:, stderr:) -> Integer
```

- **Public API**: every module, class, constant and method under `lib/` that is not marked `@api private`. Private helpers may change without a major version.
- **Checks as data**: the DSL is a builder over check objects. Nothing is evaluated from files.
- **Process execution**: the Local backend calls Open3 with argv arrays. The Docker backend calls `docker exec` with a script built from fixed templates and escaped values. The Fake backend answers from a map of argv arrays. Every backend that runs processes goes through the Runner interface, so probes can be tested without a host.
- **Timeouts**: the Open3 runner waits with `Thread#join(timeout)` and kills the process on expiry. A timed-out check gets status `error` with code `timeout`, and the other checks still run.
- **Errors**: invalid input raises `Trysac::InfraSpecChecks::Error` (a subclass of `ArgumentError`) with a `code` attribute. The library does not exit or print, except through the CLI writers passed in by the caller.
- **Global state**: none. The gem does not monkey-patch core classes.

## Quality contract

`scripts/check.rb` is the single definition of the gates; `fabrica.json` tells the factory and CI how to run it. See [TESTING.md](TESTING.md).

## Decisions

Architecture decisions are recorded in [decisions/](decisions/) as numbered ADRs.
