# Checks as data run through validated argv backends

Status: accepted (generated, pending human review)

## Context

Server verification tools built on string interpolation run whatever a package name contains, and full frameworks need a Ruby inside the target and many gems. The library must verify ports, packages, services and files without building a shell command from input.

## Decision

Checks are plain objects built by a DSL or from JSON; nothing is evaluated from files. Each value is validated by a strict grammar and a named size limit before use. Backends receive argv arrays: Local passes them to Open3 without a shell, Docker joins them into one sh -c script using Shellwords.escape only, and Fake maps argv arrays to canned output so every probe is testable. Probes parse /proc/net/tcp, os-release, apk, dpkg-query, rpm and stat output into typed results. A timeout or probe failure becomes an error result for that check only.

## Consequences

Hostile input is rejected before any process is started and the Docker script cannot be altered by a value. Every probe is covered by fast fake-backend specs, while real container behaviour is verified only in the CI conformance tier. Only Linux targets with the listed package managers are supported; other systems give the :unsupported_os error.
