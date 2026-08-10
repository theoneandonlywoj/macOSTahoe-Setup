---
name: commit-conventions
description: Use when writing a git commit message or generating a git commit command, including via /commit. Applies the Conventional Commits v1.0.0 specification (https://www.conventionalcommits.org/en/v1.0.0/) to classify changes and draft commit messages. Do not use for general git questions unrelated to commit messages.
---

# Conventional Commits

Write git commit messages that follow the Conventional Commits v1.0.0 specification. This gives the project an explicit, machine-readable history that drives SemVer bumps and changelogs.

## Structure

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

A full commit message is made of: a required type prefix, an optional scope, an optional breaking-change `!`, the required `: ` separator, and a description; then an optional body after a blank line; then optional footers after another blank line.

## Choosing the type

Pick the type that best describes the change:

| Type       | Use for                                                        | SemVer |
| ---------- | -------------------------------------------------------------- | ------ |
| `feat`     | A new feature or user-facing capability                        | MINOR  |
| `fix`      | A bug fix                                                      | PATCH  |
| `build`    | Changes to the build system or external dependencies           | —      |
| `chore`    | Routine maintenance with no user-facing impact                 | —      |
| `ci`       | Changes to CI configuration and scripts                        | —      |
| `deps`     | Changes to external dependencies                               | —      |
| `docs`     | Documentation only                                             | —      |
| `style`    | Formatting that does not affect code meaning                   | —      |
| `refactor` | Code change that is neither a fix nor a feature                | —      |
| `perf`     | A performance improvement                                      | —      |
| `test`     | Adding or correcting tests                                     | —      |
| `revert`   | Reverting a previous commit                                    | —      |

If a change fits more than one type, prefer making multiple commits. If a diff is unrelated to any single intent, split it before committing rather than forcing one message.

### Chained types

When a single change genuinely spans multiple types and cannot be split cleanly, chain the types with `+` in the prefix:

```
feat+fix: add offline mode and correct date parsing
chore+fix: bump dependencies and pin the dev toolchain
```

Rules for chained types:
- Only chain when the change is one cohesive unit — never force unrelated changes into one commit just to chain.
- The `+`-joined types act as one type prefix; scope, `!`, and `:` follow as usual, e.g. `feat+fix(api)!: ...`.
- For SemVer interpretation, use the strongest type in the chain (`feat` implies MINOR, a `fix` implies PATCH, a breaking change implies MAJOR).
- Keep the chain to the types that actually apply; prefer `+` over multi-paragraph subject lines.

## Rules (from the specification)

1. Commits MUST be prefixed with a type, followed by the optional scope, optional `!`, and a REQUIRED colon and space: `<type>: `.
2. `feat` MUST be used when the commit adds a new feature.
3. `fix` MUST be used when the commit represents a bug fix.
4. A scope MAY follow the type — a noun in parentheses describing the section of the codebase, e.g. `feat(parser): add ability to parse arrays`.
5. The description MUST immediately follow the colon and space. It is a short summary of the change.
6. The body, if present, MUST begin one blank line after the description and MAY be any number of newline-separated paragraphs.
7. Footers, if present, MUST begin one blank line after the body. Each footer is `Token: value` or `Token #value`.
8. Footer tokens MUST use `-` in place of whitespace (e.g. `Acked-by`), except `BREAKING CHANGE`.
9. Breaking changes MUST be marked either with a `!` immediately before the `:` in the prefix (e.g. `feat!:`) or with a `BREAKING CHANGE: <description>` footer (uppercase, followed by colon and space). `BREAKING-CHANGE` is synonymous.
10. Types are case-insensitive; stay consistent (lowercase). Only `BREAKING CHANGE` is case-sensitive and MUST be uppercase.

## Writing the subject (description)

- Use the **imperative mood**: "add", "fix", "remove" — as if the commit performs the action ("fix ...", not "fixed ..." or "fixes ...").
- Keep it concise and scannable; aim for under ~50 characters when possible.
- Capitalize the first word, no trailing period.
- Summarize the change, not the process.

## Writing the body

- Add a body when the subject alone is not enough context: explain the *why* and any tradeoffs, not the *what* the diff already shows.
- Start the body on a new line, one blank line after the subject.
- Use multiple paragraphs freely; wrap lines for readability.

## Footers

Use git trailer format for footers, each on its own line:

- Token must be a word token, optionally with `-` instead of spaces.
- Value after `: ` or ` #`.
- `BREAKING CHANGE: <description>` is the footer used to declare a breaking change when the `!` prefix is not used.
- A `revert` commit uses a `Refs:` footer listing the SHAs being reverted, e.g. `Refs: 676104e, a215868`.
- The commit author comes from git's configured identity; do not add attribution footers (`Co-authored-by`, `Signed-off-by`, etc.) — the commit carries only the configured author.

## Examples

```
feat: allow provided config object to extend other configs

BREAKING CHANGE: `extends` key in config file is now used for extending other config files
```

```
feat!: send an email to the customer when a product is shipped
```

```
feat(api)!: send an email to the customer when a product is shipped
```

```
fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.
```

```
docs: correct spelling of CHANGELOG
```

```
revert: let us never again speak of the noodle incident

Refs: 676104e, a215868
```

## Git command mapping

Translate the message into a git command using two `-m` flags — the subject and the body:

```bash
git commit -m "<type>(<scope>): <description>" -m "<body paragraph>"
```

Each `-m` becomes a paragraph in the final message. Always use single quotes around messages that contain double quotes or shell-special characters (e.g. `BREAKING CHANGE: ...`), or double quotes otherwise — be consistent and safe for `zsh`.
