---
name: investigate-feedback
description: Use when a user invokes /investigate-feedback, or asks to "review the PR feedback", "what did the reviewers say", "triage the comments", "go through the PR review", or similar. Pulls the PR review feedback for a pull request, triages every comment into a decision (fix / won't-fix / needs-discussion) with a workflow-impact flag, and writes an actionable feedback note to _woj/11-feedback/NNN-<slug>.md that /implement-feedback then works from. Also use when a path to an existing 11-feedback note is passed (update mode): append new feedback items to that note.
---

# Investigate Feedback

Pull the PR review feedback for a pull request and triage every comment into an actionable plan, saved as a structured feedback note under `_woj/11-feedback/` that `/implement-feedback` reads as its input. This skill sits between `/pr-gh` and `/implement-feedback` in the feature workflow.

## When to use

- The user invokes `/investigate-feedback`.
- The user asks to "review the PR feedback", "what did the reviewers say", "triage the comments", "go through the PR review", or similar phrasing.
- The user passes a file path to an existing feedback note (e.g. `/investigate-feedback _woj/11-feedback/002-...md`), or asks to "add the new comments", "incorporate the follow-up review". This is **update mode** — see "Workflow (update mode)".

The input is a PR note from `_woj/10-pr/` written by `/pr-gh`. The output is a feedback note that `/implement-feedback` reads (never modifies) and continues from in `_woj/12-implement-feedback/`.

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/11-feedback/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it names a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Read the PR note

- If the user named a PR note, use it.
- Otherwise, scan `_woj/10-pr/*.md` and use the note with the highest `NNN-` prefix (the latest PR).
- Extract the PR number, the PR URL, and the branch from the `Source` section. Read `Body`, `Checks`, `Notes`, and any `Conflict resolution` section for context.
- If no PR note exists, ask the user for the PR number or URL before pulling feedback.

### 2. Pull the feedback

Run, with `<n>` the PR number from step 1:

- `gh pr view <n> --comments` — issue comments.
- `gh pr view <n> --reviews` — review summaries and bodies.
- `gh pr view <n> --json reviews` — review-thread comments where available.

If `gh` is unavailable or the PR cannot be reached, ask the user to paste the comments verbatim and use those as the source.

### 3. Triage every comment

Go through each comment individually:

- Dedupe bots/automation (dependabot, CI bots, co-author robots): skip them, or record them as a single note if they carry a real request.
- Decide, for each remaining comment:
  - **fix** — the comment is valid and the code or workflow must change.
  - **won't-fix** — rejected, with a rationale.
  - **needs-discussion** — cannot decide without the user.
- Assess **workflow impact**: a feedback item has workflow impact if addressing it changes the process diagram in `_workflow.md` itself (adds/removes/renames steps or edges), not merely the code. Consult `_workflow.md` as the source of truth when in doubt.

### 4. Choose the filename

Write to `_woj/11-feedback/NNN-<slug>.md` where:

- `NNN` and `<slug>` **mirror the source PR note's basename** (e.g. PR note `_woj/10-pr/002-herdr-install.md` produces `_woj/11-feedback/002-herdr-install.md`), making the chain traceable.
- When there is no PR note, scan `_woj/11-feedback/*.md` for the highest existing `NNN-` prefix, add 1, and zero-pad to 3 digits (start at `001` if empty). Use a kebab-case slug of the PR subject.

Create `_woj/11-feedback/` if it does not exist. Never overwrite an existing file — the sequence number guarantees uniqueness.

### 5. Note template

    # <Short imperative title>

    ## Source

    PR: <url> (#<n>)

    ## Feedback items

    ### Item 1

    > <the comment, verbatim>

    **Decision:** fix | won't-fix | needs-discussion

    **Action:** <what to do, concretely>

    **Workflow impact:** yes | no

    ### Item 2

    > <the comment, verbatim>

    **Decision:** ...

    **Action:** ...

    **Workflow impact:** ...

    ## Summary

    - <n> fix, <n> won't-fix, <n> needs-discussion
    - <overall assessment of the review>

A note is Markdown; all fenced blocks use triple backticks. **Drop sections that add no value** (`Summary` when there is a single item) rather than leaving them empty. Quote comments verbatim so `/implement-feedback` can match each item to the code without re-pulling GitHub.

### 6. Present the decisions

Present the triage to the user and confirm before moving on: list each item, its decision, and the action. Update items flagged **needs-discussion** from the user's answers; adjust any decision the user disagrees with.

## Workflow (update mode)

When a file path to an existing feedback note is provided:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/11-feedback/`.
- Confirm the file exists and is a feedback note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not a feedback note (no `# ` title with `## Feedback items`), report the mismatch and ask the user to confirm before editing.

### 2. Pull the new feedback

- Run the same `gh` commands as step 2 of create mode against the PR recorded in the note's `## Source` (or the PR the user names).
- If `gh` is unavailable, ask the user to paste the new comments verbatim.

### 3. Append the new items

- Read the existing note and append new `### Item <n>` blocks at the end of `## Feedback items`, continuing the numbering from the last existing item.
- Keep the format identical to create mode: quoted comment, `**Decision:**`, `**Action:**`, `**Workflow impact:**`.
- Leave all existing sections and items unchanged. If a new item resolves an earlier one, append it and optionally strike through the earlier item (e.g. `- ~~<resolved item>~~`), leaving its text in place.
- Update the `## Summary` counts to include the appended items.

## Verify before finishing

- Re-read the written file and confirm the filename mirrors the source PR note (`NNN-<slug>.md`), or followed the sequence rule when there is no PR note.
- Confirm every pulled comment is represented by a `### Item <n>` block carrying a decision and a workflow-impact flag.
- Confirm `## Summary` counts match the number of items and their decisions.
- In update mode, confirm the original content is untouched and only new `### Item <n>` blocks (and the summary counts) were added.

## Reporting back

- **Create mode:** tell the user the file created (full path), the number of items, the counts by decision (fix / won't-fix / needs-discussion), and which items have workflow impact. End with the next step: `/implement-feedback` with the same `NNN-<slug>`.
- **Update mode:** tell the user which file was updated (full path), the new item numbers appended, and the updated counts by decision. Mention any earlier items struck through as resolved.
