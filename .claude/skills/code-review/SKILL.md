---
name: code-review
description: "Review the diff between HEAD and a fixed point (commit, branch, tag, or merge-base) along two axes — Standards (conformance to AGENTS.md and docs/) and Spec (matches the originating issue/PRD/spec). Use whenever the user wants to review a branch, a PR, work-in-progress changes, or asks to 'review since X' / 'review the diff' / 'what changed since Y' / 'check this branch against the spec' — even if they don't say 'code review'."
user-invocable: true
disable-model-invocation: false
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Task"]
---

# /code-review

Two-axis review of the diff between `HEAD` and a fixed point the user supplies:

- **Standards** — does the code conform to this repo's documented coding standards, where `AGENTS.md` (repo root) and every file under `docs/` are the source of truth.
- **Spec** — does the code faithfully implement the originating issue / PRD / spec.

Both axes are reviewed sequentially in this agent, with an explicit role switch between them so they don't pollute each other's reasoning. The skill then aggregates their findings, flags any drift between the docs and the code, and writes a `REVIEW.md` to the repo root.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other. Do not collapse them into a single ranked list.

## Why AGENTS.md and docs/ are the standards source

`AGENTS.md` (repo root) and everything under `docs/` are where this repo records how code should be written and how the project fits together. They are peers: both are read in full and applied to the diff. Where they disagree, `AGENTS.md` wins — it is the closer-to-code contract. If `AGENTS.md` is missing, say so in `## Sources` as an actionable nudge ("no AGENTS.md found — Standards axis fell back to smell baseline + docs/ only") and continue; the Standards axis still runs on whatever docs/ contains plus the smell baseline below.

## Process

### 1. Pin the fixed point

Whatever the user said is the fixed point — a commit SHA, branch name, tag, `main`, `HEAD~5`, `origin/develop`, etc.

- If the user didn't specify one, default to `main` if it resolves locally, else `master`, else `origin/main`, else `origin/master`. If none resolve, ask for one and stop.
- Confirm the ref resolves: `git rev-parse --verify <fixed-point>`. A bad ref should fail here, not inside a review.
- Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Also capture `git log <fixed-point>..HEAD --oneline` for the commit list.
- Confirm the diff is non-empty (`git diff <fixed-point>...HEAD --stat` shows files). An empty diff is a stop — tell the user there are no changes to review.

If the user names a subdirectory or module ("focus on auth"), note it and narrow the diff with `git diff <fixed-point>...HEAD -- <path>` for the substantive review, but still run staleness and spec checks against the whole branch diff.

### 2. Load the standards sources

Read these in full before reviewing:

1. `AGENTS.md` in the repository root (if it exists).
2. Every Markdown file under `docs/` (use `Glob` with `docs/**/*.md`).

Scan them for: documented conventions, naming rules, structural claims (module names, commands, file paths, architecture), and any area the diff touches. Keep the file list and a short note of what each contains — it feeds `## Sources` at the end.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below — a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation — and, like any standard here, skip anything tooling already enforces.

Each smell reads _what it is_ → _how to fix_; match it against the diff:

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

### 3. Find the spec

Look for the originating spec, in this order:

1. **Issue references in the commit messages** — scan `git log <fixed-point>..HEAD --oneline` for `#N`, `Closes #N`, `Fixes #N`, GitLab `!N`. For each ref, run `gh auth status` first; if it fails, tell the user and fall through to step 2. If authed, fetch via:
   - `gh issue view <N> --json title,body,labels,state` for `#N`
   - `gh pr view <N> --json title,body,labels,state` when the ref looks like a PR number
   Use the fetched `title` + `body` as the spec text.
2. **A path the user passed as an argument** — if the user said "review against docs/specs/auth.md", read it.
3. **A PRD/spec file under `docs/specs/`, `docs/`, or `.scratch/`** matching the branch name or feature. Heuristic: branch name slug appears in the filename, or the file's title mentions the feature the commits describe.
4. **Nothing found** — ask the user where the spec is. If they say there isn't one, the **Spec** axis will report "no spec available" and the Standards axis still runs.

### 4. Standards review (role-switch)

Switch role: you are now the **Standards reviewer**. Apply the loaded standards to the diff.

Report — per file/hunk where relevant — two categories:

- **(a) Documented-standard breaches**: every place the diff violates a rule in `AGENTS.md` or `docs/`. Cite the standard: the file path and the rule (quote a short snippet). These can be hard violations.
- **(b) Baseline smells**: any smell from the baseline you spot. Name it ("possible Feature Envy") and quote the hunk. These are always judgement calls — label them as such.

Rules:
- A documented repo standard overrides the baseline. Where the repo endorses something the baseline would flag, suppress the smell and say so.
- Skip anything tooling already enforces (linters, formatters, type checkers the repo runs).
- Distinguish hard violations (documented-standard breaches) from judgement calls (baseline smells) in the wording.
- Keep this section under ~400 words.

Write the result to memory as the **Standards report** (do not print yet — it gets aggregated in step 7).

### 5. Spec review (role-switch)

Switch role: you are now the **Spec reviewer**. Compare the diff against the spec found in step 3.

Report three categories:

- **(a) Missing or partial**: requirements the spec asked for that the diff doesn't deliver or only partially delivers.
- **(b) Scope creep**: behaviour in the diff the spec didn't ask for.
- **(c) Implemented-but-wrong**: requirements that look implemented but where the implementation looks incorrect.

Quote the spec line for each finding, then point to the hunk.

If no spec was found in step 3, write only: "No spec available." and skip the rest.

Keep this section under ~400 words. Write it to memory as the **Spec report**.

### 6. Staleness flag

For each diff hunk that changes a behaviour, file path, command, module name, or convention that is documented in `AGENTS.md` or `docs/` — and the branch diff does **not** touch that doc file — record a "docs drifted from code" finding under `## Sources`:

- The doc file path + the line/snippet that describes the old behaviour.
- The hunk (file + line range) that now contradicts it.
- A one-line description of the contradiction.

This is the "diff contradicts docs" signal. It catches the most actionable kind of staleness: code moving forward while the contract stays stale.

Also flag under `## Sources`:

- **Missing sources**: `AGENTS.md` absent (the current state of this repo), or `docs/` empty. These are actionable nudges, not errors — the review still runs.
- **Untouched but relevant docs**: a doc file under `docs/` the diff plausibly should have updated but didn't, even when the contradiction isn't a clean "old text vs new code" case. Keep this brief — list the file and why it looks relevant.

### 7. Aggregate and write `REVIEW.md`

Write the report to `REVIEW.md` in the repository root with this structure:

```markdown
# Code Review — <fixed-point>..HEAD

<!-- one-line summary of the branch -->

## Commits
<!-- git log --oneline, verbatim -->

## Standards
<!-- the Standards report from step 4 -->

## Spec
<!-- the Spec report from step 5 -->

## Sources
<!-- standards sources used, staleness flags, missing sources -->
```

Rules:

- Present the two reports under `## Standards` and `## Spec` **verbatim or lightly cleaned** — do not merge, rerank, or score them against each other. The separation is the point (see _Why two axes_).
- End the file with a one-line summary: total findings per axis, and the worst issue *within each axis* (if any). Do not pick a single winner across axes.
- Do not run `git add` on `REVIEW.md`.

### 8. Print summary in chat

After writing `REVIEW.md`, print a short summary in chat:

- The path to `REVIEW.md`.
- Per-axis finding count and the worst issue in each axis (one line each).
- Any staleness flags from `## Sources` (one line each), starting with missing sources.
- A closing line, e.g. "Full report in REVIEW.md."

Do not print the full report in chat — it's in the file.

## Notes

- If the branch is a single commit, keep both reviews short. Do not pad.
- If the diff mixes unrelated changes across modules, say so at the top of `REVIEW.md` and suggest splitting — but still review what's there.
- Keep it honest: don't claim a standard was breached without citing it; don't claim a spec requirement was missed without quoting it.
- `/code-review` and explicit "review since X" requests are the trigger. A bare "what changed" without a fixed point should default sensibly (step 1) rather than refusing.
- `REVIEW.md` is local only and is not part of the branch diff. Mention this to the user if they seem likely to commit it by accident.
- Spec fetch failures (no `gh`, not authed, no issue found) are not fatal — fall through to file-based specs, then to "no spec available."