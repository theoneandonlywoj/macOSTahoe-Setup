---
name: commit
description: "Generate a short Conventional Commit command from staged changes and ask whether to execute it. Use whenever the user asks for a commit message, wants to write/compose/draft a commit, says 'what should I commit', wants a git commit -m command, or wants to know the commit message for already-staged files — even if they don't explicitly say 'commit message'. Ask-before-run: never runs git commit until explicit confirmation, and never runs git add."
user-invocable: true
disable-model-invocation: false
allowed-tools: ["Bash", "Read"]
---

# /commit

Generate a short Conventional Commits message from the **staged** changes (files already `git add`-ed but not yet committed), **print a ready-to-run `git commit -m ...` command**, and ask whether to run it. Do not commit unless the user explicitly confirms.

## Why ask before running

The user should be able to review the exact commit command before it runs. Running `git commit` without confirmation is surprising and hard to undo. So: analyze, draft a short command, print it, then ask whether to execute it. If the user says "yes", "commit it", or "go ahead", run the printed command exactly. Never run `git add`.

## Workflow

1. Run `git status --short` to see what's staged vs unstaged. If nothing is staged (`git diff --staged` is empty), tell the user and stop — don't fabricate a message from unstaged changes.
2. Run `git diff --staged` to read the actual staged diff. For large diffs, also run `git diff --staged --stat` first for an overview, then read the full diff in chunks.
3. Classify the change into a Conventional Commits type:
   - `feat` — new feature for the user
   - `fix` — bug fix
   - `docs` — documentation only
   - `style` — formatting, whitespace, no code change
   - `refactor` — code change that neither fixes a bug nor adds a feature
   - `perf` — performance improvement
   - `test` — adding/fixing tests
   - `build` — build system or external dependencies
   - `ci` — CI configuration
   - `chore` — maintenance, tooling, no production code
   - `revert` — revert a previous commit
4. Draft the message:
   - **Subject line**: `<type>(<optional scope>): <imperative summary in lowercase>` — ≤ 72 chars, no trailing period, imperative mood ("add" not "added").
   - **Scope**: optional, use a sensible module name (e.g. `feat(auth): ...`). Omit if there's no clear scope.
   - Keep the command short: use a subject-only commit by default. Do not add body paragraphs for normal commits.
   - **Footer**: add only if required for `BREAKING CHANGE: <desc>` or issue refs (`Closes #123`).
5. Convert the message into a shell command:
   - Normal case: `git commit -m "<subject>"`.
   - Required footer: `git commit -m "<subject>" -m "<footer>"`.
   - Escape embedded double quotes, backslashes, dollar signs, and backticks so the command is safe to paste into a shell.
6. **Print** the short command in a fenced `bash` code block so the user can copy it cleanly. Then ask: `Run this commit command?`

## Examples

**Example 1 — simple feature**
Input (staged): added JWT login flow in `src/auth.ts`
Output:
```bash
git commit -m "feat(auth): add jwt-based login"
```
Run this commit command?

**Example 2 — bug fix, multi-file**
Input (staged): fixed null deref in user profile loading across `loader.go` and `loader_test.go`
Output:
```bash
git commit -m "fix(loader): guard against nil user in profile path"
```
Run this commit command?

**Example 3 — chore, single line is fine**
Input (staged): bumped a dev dependency
Output:
```bash
git commit -m "chore: bump eslint to 9.1.0"
```
Run this commit command?

## Notes

- Base the message **only** on staged changes. If the user asks "what about my unstaged changes?", point them out but don't include them in the commit message.
- If the staged change is huge and spans many types, pick the dominant type for the short command, or suggest splitting into multiple commits.
- Keep it concise. The subject is the headline. Output the command, then ask whether to run it.
