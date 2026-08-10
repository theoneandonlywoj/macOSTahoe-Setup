---
description: Review staged changes and commit them with a Conventional Commits message (runs git commit after confirmation).
agent: build
---

Review the files already added with `git add` and commit them following Conventional Commits best practices. Load the `commit-conventions` skill and follow it for message structure, types, scopes, breaking changes, body, and footers.

## Workflow

1. **Inspect what is staged.** Run `git status --short` and `git diff --cached --stat`, then read the full diff with `git diff --cached`. If the diff is large, read the changed files with the read tool where the diff alone is not enough to understand intent.

2. **If nothing is staged**, do not commit. Report that no changes are staged and show the user `git add <FILE>` usage so they can stage the files they want.

3. **Classify the changes** using the `commit-conventions` skill:
   - Determine the **type** (`feat`, `fix`, `build`, `chore`, `ci`, `deps`, `docs`, `style`, `refactor`, `perf`, `test`, `revert`) that best fits the combined diff. If the change genuinely spans multiple types and cannot be split, chain them with `+` (e.g. `feat+fix`) per the skill.
   - Determine an optional **scope** — a noun naming the section of the codebase the change touches (e.g. `skills`, `docs`, `zsh`, `scripts`).
   - Decide whether this is a **breaking change** (add `!` to the prefix or a `BREAKING CHANGE:` footer).
   - Write an imperative **subject** under ~50 characters.
   - Write a concise **body** explaining the *why* when the subject alone is not enough. Split unrelated changes into separate commits and tell the user if they should stage less, rather than forcing one message.

4. **Build the git command.** Translate the message into `git commit` with one `-m` flag for the subject and one for the body: `git commit -m "<type>(<scope>): <description>" -m "<body>"`.
   - Do not add footers (`Reviewed-by:`, `Refs:`, `Co-authored-by:`, `Signed-off-by:`, etc.).
   - If the user invoked with `--amend` as an argument, use `git commit --amend` instead.
   - Quote safely for `zsh`: single quotes around messages containing double quotes or shell-special characters.
   - Do not include `git add` in the command — the user staged files explicitly with `git add <FILE>` and only those should be committed.
   - **Use the author from git configuration.** Let the commit use whatever author git already has configured — do not pass `--author` or `-c user.name=...`/`-c user.email=...`, and do not suggest the user configure one.

5. **Present and confirm.** Show the user:
   - A short review of what is staged (files and a one-line summary of each).
   - The exact `git commit` command and the resulting commit message it will produce.
   - If `--amend` was requested, note that the previous commit message/history will be rewritten.
   Then **ask for confirmation** before running it. Run the command only after explicit approval.

6. **On confirmation, run the command.** Verify it succeeded with `git log -1 --stat` (or `git status --short` after an amend) and report the result. If the commit fails, surface the error and propose a corrected command; do not attempt workarounds without asking.

If the user provided additional arguments (a message, `--amend`, or an issue reference), incorporate them. Any remaining `$ARGUMENTS` not otherwise used should be treated as hints for the commit message.

$ARGUMENTS
