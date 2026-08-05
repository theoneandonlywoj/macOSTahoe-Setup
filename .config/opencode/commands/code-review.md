---
description: Review the diff between HEAD and a fixed point along two axes — Standards (conformance to AGENTS.md and docs/) and Spec (matches the originating issue/PRD). Use when the user wants to review a branch, a PR, WIP changes, or asks to "review since X" / "review the diff" / "what changed" — even if they don't say "code review"
---

The user invoked `/code-review` with this request:

`$ARGUMENTS`

Two-axis review of the diff between `HEAD` and a fixed point:

- **Standards** — does the code conform to this repo's documented coding standards, where `AGENTS.md` (repo root) and every file under `docs/` are the source of truth.
- **Spec** — does the code faithfully implement the originating issue / PRD / spec.

Report them separately — do not merge or rerank. A change can pass one axis and fail the other; reporting them separately stops one from masking the other.

## Pin the fixed point

Whatever the user said in `$ARGUMENTS` is the fixed point — a commit SHA, branch name, tag, `main`, `HEAD~5`, `origin/develop`, etc.

- If `$ARGUMENTS` is empty, default to `main` if it resolves (`git rev-parse --verify main`), else `master`, else `origin/main`, else `origin/master`. If none resolve, ask for one and stop.
- Confirm the ref resolves: `git rev-parse --verify <fixed-point>`. A bad ref fails here, not inside a review.
- Capture the diff: `git diff <fixed-point>...HEAD` (three-dot, compares against the merge-base). Also capture `git log <fixed-point>..HEAD --oneline` for the commit list.
- If the diff is empty (`git diff <fixed-point>...HEAD --stat` shows nothing), stop — tell the user there are no changes to review.
- If the user named a subdirectory or module ("focus on auth"), narrow the substantive review with `git diff <fixed-point>...HEAD -- <path>` but still run staleness and spec checks against the whole branch diff.

## Load the standards sources

Read these in full before reviewing:

1. `AGENTS.md` in the repository root (if it exists).
2. Every Markdown file under `docs/` (use `Glob` with `docs/**/*.md`).

`AGENTS.md` wins on conflicts; both are peers otherwise. If `AGENTS.md` is missing, note it in `## Sources` as an actionable nudge ("no AGENTS.md found — Standards axis fell back to smell baseline + docs/ only") and continue — the Standards axis still runs on whatever docs/ contains plus the smell baseline.

## Find the spec

Look for the originating spec, in this order:

1. Issue references in the commit messages — scan `git log <fixed-point>..HEAD --oneline` for `#N`, `Closes #N`, `Fixes #N`, GitLab `!N`. Run `gh auth status` first; if it fails, tell the user and fall through. If authed, fetch via `gh issue view <N> --json title,body,labels,state` (for `#N`) or `gh pr view <N> --json title,body,labels,state` (when the ref looks like a PR). Use the fetched `title` + `body` as the spec text.
2. A path the user passed as an argument — if the user said "review against docs/specs/auth.md", read it.
3. A PRD/spec file under `docs/specs/`, `docs/`, or `.scratch/` matching the branch name or feature. Heuristic: branch name slug appears in the filename, or the file's title mentions the feature the commits describe.
4. Nothing found — ask the user where the spec is. If they say there isn't one, the Spec axis reports "no spec available" and the Standards axis still runs.

## Standards review

Switch role: you are the **Standards reviewer**. Apply the loaded standards to the diff.

Report — per file/hunk where relevant:

- **(a) Documented-standard breaches**: every place the diff violates a rule in `AGENTS.md` or `docs/`. Cite the standard: the file path and the rule (quote a short snippet). These can be hard violations.
- **(b) Baseline smells**: any smell from the baseline below. Name it ("possible Feature Envy") and quote the hunk. These are always judgement calls — label them as such.

Rules:
- A documented repo standard overrides the baseline. Where the repo endorses something the baseline would flag, suppress the smell and say so.
- Skip anything tooling already enforces (linters, formatters, type checkers the repo runs).
- Keep this section under ~400 words.

Smell baseline (Fowler, _Refactoring_ ch.3) — each reads _what it is_ → _how to fix_; match against the diff:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

## Spec review

Switch role: you are the **Spec reviewer**. Compare the diff against the spec.

Report three categories:

- **(a) Missing or partial**: requirements the spec asked for that the diff doesn't deliver or only partially delivers.
- **(b) Scope creep**: behaviour in the diff the spec didn't ask for.
- **(c) Implemented-but-wrong**: requirements that look implemented but where the implementation looks incorrect.

Quote the spec line for each finding, then point to the hunk. If no spec was found, write only: "No spec available." and skip the rest. Keep this section under ~400 words.

## Staleness flag

For each diff hunk that changes a behaviour, file path, command, module name, or convention that is documented in `AGENTS.md` or `docs/` — and the branch diff does **not** touch that doc file — record a "docs drifted from code" finding under `## Sources`:

- The doc file path + the line/snippet that describes the old behaviour.
- The hunk (file + line range) that now contradicts it.
- A one-line description of the contradiction.

Also flag under `## Sources`:

- **Missing sources**: `AGENTS.md` absent, or `docs/` empty. Actionable nudges, not errors.
- **Untouched but relevant docs**: a doc file under `docs/` the diff plausibly should have updated but didn't, even when the contradiction isn't a clean "old text vs new code" case. Keep brief.

## Aggregate and write `REVIEW.md`

Write the report to `REVIEW.md` in the repository root with this structure:

```markdown
# Code Review — <fixed-point>..HEAD

<!-- one-line summary of the branch -->

## Commits
<!-- git log --oneline, verbatim -->

## Standards
<!-- the Standards report -->

## Spec
<!-- the Spec report -->

## Sources
<!-- standards sources used, staleness flags, missing sources -->
```

Rules:

- Present the two reports under `## Standards` and `## Spec` **verbatim or lightly cleaned** — do not merge, rerank, or score them against each other. The separation is the point.
- End the file with a one-line summary: total findings per axis, and the worst issue *within each axis* (if any). Do not pick a single winner across axes.
- Do not run `git add` on `REVIEW.md`.

## Print summary in chat

After writing `REVIEW.md`, print:

- The path to `REVIEW.md`.
- Per-axis finding count and the worst issue in each axis (one line each).
- Any staleness flags from `## Sources` (one line each), starting with missing sources.
- A closing line, e.g. "Full report in REVIEW.md."

Do not print the full report in chat — it's in the file. Mention that `REVIEW.md` is local only and not part of the branch diff if the user seems likely to commit it by accident.

## Notes

- If the branch is a single commit, keep both reviews short. Do not pad.
- If the diff mixes unrelated changes across modules, say so at the top of `REVIEW.md` and suggest splitting — but still review what's there.
- Don't claim a standard was breached without citing it; don't claim a spec requirement was missed without quoting it.
- Spec fetch failures (no `gh`, not authed, no issue found) are not fatal — fall through to file-based specs, then to "no spec available."