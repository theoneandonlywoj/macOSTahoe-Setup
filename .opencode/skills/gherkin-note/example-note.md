# Install herdr script on macOS setup

## Source

> On a fresh macOS setup, install the herdr dotfiles script so my configuration is applied automatically. I should be able to re-run the setup and get the same result, and the script should be on the PATH afterwards.

## Assumptions

- "install" means cloning the herdr repository and linking the script into `~/.local/bin`.
- The shell used for PATH is zsh (macOS default).
- Re-running the installation must be idempotent.

## Open questions

- Should herdr be installed per-user or system-wide? (assumed per-user, `~/.local/bin`)
- ~~Does the install step require sudo?~~ (resolved: no, the per-user install runs without it)

## Feature

```gherkin
Feature: Install herdr script during macOS setup
  As a developer setting up a new Mac
  I want herdr installed and available on the PATH
  So that my dotfiles are managed and applied automatically
```

## Background

```gherkin
Background:
  Given a fresh macOS setup with zsh as the default shell
```

## Scenarios

```gherkin
Scenario: Install herdr on a fresh machine
  Given herdr is not installed
  When the setup script runs
  Then herdr is available on the PATH
  And herdr version prints a version number

Scenario: Re-run installation after a previous install
  Given herdr is already installed
  When the setup script runs again
  Then no duplicate install happens
  And herdr remains functional

Scenario Outline: Install a specific herdr version
  Given herdr is not installed
  When the setup script runs with version <version>
  Then herdr version reports <version> on the PATH

Examples:
  | version |
  | 0.9.4   |
  | latest  |
```

## Conclusions

- Per-user install into `~/.local/bin` confirmed; no sudo required.
- Re-running the setup is idempotent and leaves herdr functional.
