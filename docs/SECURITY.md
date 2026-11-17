# Security notes

## Threat model

The gem `u954-infra-spec-checks` runs fixed commands on a local host or inside a Docker container. It has no network code of its own. The main risks are:

- **Supply chain**: a compromised gem or CI action. Mitigation: standard library only, every gem pinned by the committed `Gemfile.lock` (frozen installs), bundler-audit (the Ruby Advisory Database) and OSV-Scanner over `Gemfile.lock` in the gates, Dependabot weekly updates, actions pinned by commit SHA, minimal workflow permissions, MFA required to publish (`rubygems_mfa_required`).
- **Leaked secrets**: tokens committed by mistake. Mitigation: `gitleaks` runs in the local gates and in CI; `.env` files and RubyGems credentials are never committed.
- **Command injection**: package names, paths, container names and values reach the process layer. Mitigation: the Local backend passes argv arrays to Open3, never a shell string; the Docker backend builds its script from fixed templates with `Shellwords.escape` applied to validated values; names, paths, modes and ports are validated before use (names at most 128 characters, paths absolute, at most 4096 bytes, without NUL or newline, container names matching a fixed pattern).
- **Insecure code**: code evaluation, object injection through `Marshal.load` or unsafe YAML, method dispatch chosen by input (`send`), disabled TLS verification. Mitigation: RuboCop's Security and Lint cops and the factory's Semgrep rules (`.semgrep/factory-rules.yml`, `nosemgrep` ignored); the fix is made in the code instead of silencing the rule.
- **Untrusted input**: callers may pass hostile strings, and a checks file may be large. Mitigation: a checks file is limited to 1048576 bytes and 1000 checks; errors carry a code and a message of at most 200 characters of input; checks files are parsed as JSON and never evaluated.

## Not defended

- A target that lies: the results are only as trustworthy as the `/proc`, `stat`, package-manager and `systemctl` output the target returns. A compromised container can report false results.
- Commands run by `command(...)` checks execute the named program on the target with the caller's privileges. The gem does not sandbox them.
- Timeouts stop the local process started by the runner. They do not clean up child processes that the target program started.
- Timeouts and output size limits apply to each check; the gem does not bound total run time of a suite.
- No authentication, encryption or access control is provided for backends; the Docker backend relies on the local Docker daemon permissions.

## Publishing

Releases are git tags; publishing on RubyGems needs an account with MFA, whose credentials are never stored in the repository.

To report a vulnerability, see [SECURITY.md](../SECURITY.md).
