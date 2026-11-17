# Testing

## Running

```sh
bundle exec rspec        # specs, property specs included
ruby scripts/check.rb    # every gate, as CI and the factory run it
```

## Policy

- Line coverage of `lib/` (measured by SimpleCov) must stay at or above 80 %; the gate fails below it, and `# :nocov:` markers are not honoured.
- Specs exercise the public API. They assert every observable effect: returned values, raised errors (`raise_error`) and their messages.
- Property specs state invariants such as idempotence or round trips over inputs generated with a seeded `Random`, so every run checks the same cases.
- Each bug fix starts with a failing spec that reproduces it.
- Specs are deterministic: no network, no wall clock, no dependence on order (RSpec runs them in random order).
- Backend tests use `Backends::Fake` or a stub runner, so no real process is started in the local tier.

## Tiers

- Local tier (every gate run, coverage measured here): unit and property specs, plus checks on small fixtures kept in the repository. The fixtures are hand-written files that follow the documented formats of `/proc/net/tcp`, `apk`, `dpkg-query`, `rpm` and `stat`.
- CI tier: conformance that needs Docker and a real container. Such examples are tagged `:conformance`; the tests gate excludes the tag (`--tag ~conformance`) unless `scripts/check.rb` runs with `FABRICA_CI=1`, while RuboCop always checks the code. The CI `conformance` job sets `FABRICA_CI=1` and runs the full suite against `nginx:1.30.5-alpine` pinned by digest. Specs call `skip` with a clear message when `docker` is missing.

## Layout

Specs live in `spec/`, mirroring `lib/` (`spec/trysac/infra_spec_checks/*_spec.rb`), and start with `require "spec_helper"`. Fixtures and golden files go in `spec/fixtures/` (read them with `File.join(__dir__, "fixtures", ...)` relative to the spec).
