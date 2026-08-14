---
name: w-commit
description: Generate a commit message from staged changes and commit after user approval. Use when the user asks to commit changes or runs /w-commit.
---

The commit workflow is enforced by the `w-commit` plugin (`.opencode/plugins/w-commit.ts`), which registers the `w_commit_propose` and `w_commit_execute` tools and blocks direct `git commit` via bash. Your job is to drive those tools. Follow these steps exactly:

1. Run `git diff --cached --stat` to see which files are staged. If the diff is empty, run `git status --short` to confirm. If nothing is staged, tell the user nothing is staged and that they should run `git add <file>` first, then stop.
2. Run `git diff --cached` and summarize the change.
3. Write ONE commit message in this repository's style: conventional prefixes (`feat:`, `fix:`, `chore:`, `docs:`, `other:`, `conf:`, etc.) followed by an imperative summary. Chain multiple prefixes with `+` when the change spans several types, e.g. `docs+chore: ...`, `feat+fix: ...` (as in existing commits like `feat+docs: herdr configuration and docs`).
4. Call the `w_commit_propose` tool with `message` set to the commit message from step 3. The tool returns the mandatory proposal block (staged files + message). Do not print anything yourself: present the tool result verbatim as the ONLY output of this step, with no intro text, no summary, and no trailing text.
5. Ask the user for approval using the built-in `question` tool. The pop-up only renders the question text (the `w_commit_propose` tool result is hidden by default in the TUI), so embed the ENTIRE commit message and the staged files in the question text so the user can review them in the pop-up. Options:
   - "Yes, commit" — approve the proposal as-is
   - "Add more information" — the user wants to add details to the commit
   - "No, cancel" — abort the commit
   The pop-up also lets the user type their own answer; treat any typed free-form text as approval with that text as extra information.
6. Only after the user approves:
   - If the user picked "Add more information", call `question` again asking what they want to add (they type it in as a custom answer).
   - Call `w_commit_execute` with `message` set to the EXACT message from step 4 and `extra` set to any additional information the user provided (omit `extra` if there is none).
   - The plugin runs the commit itself with the repo's `user.name`/`user.email` and the current timestamp, then returns the commit hash. Report that result to the user.
7. If the user cancels, do not commit and do not call `w_commit_execute`.

Rules:

- Never run `git commit` via the bash tool: the plugin blocks it.
- Never call `w_commit_execute` without a preceding `w_commit_propose` and explicit user approval.
- Never change the message between proposal and execution: the plugin rejects mismatches.
- Never add `Co-authored-by:` trailers or any other agent attribution to the commit message.