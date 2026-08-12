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
| `(any)`    | Marked with `!` or a `BREAKING CHANGE:` footer                 | MAJOR  |

A breaking change bumps MAJOR regardless of type — `!` in the prefix or a `BREAKING CHANGE:` footer can appear on a commit of ANY type.

Custom types are spec-permitted: the spec fixes no type list, and this repo's history uses e.g. `other:` and even typeless subjects. `deps` is a repo extension — the spec's and Angular's lists use `build` for dependency changes.

If a change fits more than one type, make multiple commits whenever possible (spec FAQ) — the only sanctioned path; see Chained types. If a diff is unrelated to any single intent, split it before committing rather than forcing one message.

### Chained types

The spec sanctions exactly one path when a change spans types: **make multiple commits whenever possible** (spec FAQ). Split-first decision procedure:

1. Can the diff be split into self-contained commits, each with its own intent and history? Split it — one type per commit.
2. Would any split fragment be broken, incomplete, or meaningless on its own? Keep one commit and use the type of the dominant intent; otherwise step 1 applies.

Split-vs-chain criterion: a diff is **unrelated** (split it) when removing one part leaves the rest complete and independently useful — e.g. a dependency bump bundled with a function rename. A diff is **genuinely cohesive** when the parts only make sense together — e.g. renaming a config key and updating every place that reads it.

Chained prefixes (`feat+fix:`) are a **non-standard repo extension**: they are not in the v1.0.0 spec, and strict parsers (semantic-release, commitlint) treat them as invalid or no-release. Use them only if the repo explicitly opts in via a documented extension policy. When opted in: the `+`-joined types act as one prefix (scope, `!`, and `:` follow as usual), keep the chain to the types that actually apply, and prefer `+` over multi-paragraph subject lines:

```
feat+fix: add offline mode and correct date parsing
```

`chore+fix: bump dependencies and pin the dev toolchain` is an anti-pattern even under the extension — it bundles two unrelated changes (a routine dependency bump and a toolchain pin) that belong in separate commits.

## Rules (from the specification)

1. Commits MUST be prefixed with a type, followed by the optional scope, optional `!`, and a REQUIRED colon and space: `<type>: `.
2. `feat` MUST be used when the commit adds a new feature.
3. `fix` MUST be used when the commit represents a bug fix.
4. A scope MAY follow the type — a noun in parentheses describing the section of the codebase, e.g. `feat(parser): add ability to parse arrays`.
5. The description MUST immediately follow the colon and space. It is a short summary of the change.
6. The body, if present, MUST begin one blank line after the description and MAY be any number of newline-separated paragraphs.
7. Footers, if present, MUST begin one blank line after the body. Each footer is `Token: value` or `Token #value`.
8. Footer tokens MUST use `-` in place of whitespace (e.g. `Acked-by`), except `BREAKING CHANGE`.
9. Breaking changes MUST be marked either with a `!` immediately before the `:` in the prefix (e.g. `feat!:`) or with a `BREAKING CHANGE: <description>` footer (uppercase, followed by colon and space). `BREAKING-CHANGE` is synonymous. When `!` is used, the description SHALL describe the breaking change.
10. Types are case-insensitive; stay consistent (lowercase). Only `BREAKING CHANGE` is case-sensitive and MUST be uppercase.

## Writing the subject (description)

- Use the **imperative mood**: "add", "fix", "remove" — as if the commit performs the action ("fix ...", not "fixed ..." or "fixes ...").
- Keep it concise and scannable; aim for under ~50 characters when possible.
- Team style, not spec: capitalize the first word and use no trailing period — the spec is silent on case, and the examples in this skill (and the spec's) are lowercase.
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
- The commit author comes from git's configured identity. Repo policy, not spec: do not add attribution footers (`Co-authored-by`, `Signed-off-by`, etc.) — the commit carries only the configured author. The spec permits them (its example footer is `Reviewed-by: Z`), and DCO projects require `Signed-off-by`.

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

A subject + body + footer message has three paragraphs, so use three `-m` flags — one each for the subject, the body, and the footer:

```bash
git commit -m "<type>(<scope>): <description>" -m "<body paragraph>" -m "<footer token: value>"
```

Each `-m` becomes a paragraph in the final message. When the prefix carries `!`, the description SHALL describe the breaking change (rule 9).

Quoting: single quotes are the safer default — they tolerate double quotes and shell-special characters (e.g. `BREAKING CHANGE: ...`) — but an apostrophe cannot appear inside a single-quoted string, so for such messages use double quotes and escape any inner `"`, `$`, or backtick, e.g. `git commit -m "fix: handle the parser's edge cases"`. Be consistent and safe for `zsh`.
