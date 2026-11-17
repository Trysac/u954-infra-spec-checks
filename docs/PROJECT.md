# Project record

## Objective

Give teams a way to define server and container checks as data and run them without a shell on the input. Checks cover listening ports, installed packages, running services, file modes and command exit statuses. Results are typed and parsed from `/proc` and package-manager output, so they can be read reliably.

## Scope

- In scope: the public API documented in [README.md](../README.md): the `define` DSL, `Suite.from_json`, `Suite#run`, `Report`, the Local, Docker and Fake backends, the `CLI.run` entry point, and the `Text` helper.
- In scope: Linux targets with `/proc`, Alpine, Debian, Ubuntu, Fedora, RHEL, Rocky and AlmaLinux package managers.
- Out of scope: SSH and WinRM backends, Windows targets, kernel parameters, users and groups, network reachability checks, and Ruby DSL files loaded from disk.
- Out of scope: anything that needs dependencies or I/O without an accepted ADR.

## Timeline

| Date | Event |
|---|---|
| 2026 | Repository created from the factory utility template. |

## Effort metrics

Values are filled by the factory. A value that has not been measured reads "pending measurement".

| Metric | Value |
|---|---|
| Tokens (input / output) | 462352 / 211067 |
| Hours (human) | pending measurement |
| Cost (USD) | 1.4077 |

## Factory run u954 (measured from API usage)

| Date (UTC) | Phase | Model | Batch | Input | Output | Cache write | Cache read | Cost (USD) |
|---|---|---|---|---|---|---|---|---|
| 2026-11-17 | generation | claude-sonnet-5-5 | yes | 3093 | 128000 | 5813 | 0 | 0.6547 |
| 2026-11-17 | generation | claude-sonnet-5-5 | yes | 3093 | 54641 | 0 | 5813 | 0.2769 |
| 2026-11-17 | fix-1 | claude-sonnet-5-5 | no | 6 | 627 | 17101 | 32518 | 0.0523 |
| 2026-11-17 | fix-2 | claude-sonnet-5-5 | no | 14 | 15762 | 46265 | 244076 | 0.2977 |
| 2026-11-17 | fix-3 | claude-sonnet-5-5 | no | 8 | 1775 | 8848 | 60604 | 0.0459 |
| 2026-11-17 | fix-4 | claude-sonnet-5-5 | no | 6 | 630 | 7708 | 43446 | 0.0299 |
| 2026-11-17 | fix-1 | claude-sonnet-5-5 | no | 8 | 1466 | 9810 | 61355 | 0.0453 |
| 2026-11-17 | audit | claude-sonnet-5-5 | no | 0 | 0 | 0 | 0 | 0.0000 |
| 2026-11-17 | docs | claude-haiku-5-5 | no | 8312 | 8166 | 0 | 0 | 0.0049 |

Total: $1.4077. Prices: Anthropic list prices. Providers serve the current version of each model id, so the date tells which version answered; versions, launch stages and price sources per line are in the factory's model register (docs/MODELS.md).
