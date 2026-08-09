# Matt Pocock Engineering Skills Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a standalone Zsh installer that interactively installs only Matt Pocock's engineering skills for detected Claude Code, Codex, and OpenCode CLIs.

**Architecture:** Clone the upstream repository into a temporary directory, enumerate only direct skill directories under `skills/engineering`, and copy those directories to each selected CLI's global skill directory. Reuse the existing `skills/superpowers.zsh` interaction model while using OpenCode's native global skill path instead of a plugin.

**Tech Stack:** Zsh, Git, standard macOS command-line tools.

## Global Constraints

- Use the upstream repository `https://github.com/mattpocock/skills.git`.
- Install only `skills/engineering/*`; do not install `skills/productivity/*` or other catalog directories.
- Detect `claude`, `codex`, and `opencode` with `command -v` before prompting.
- Install to `~/.claude/skills`, `~/.codex/skills`, and `~/.config/opencode/skills` respectively.
- Preserve existing skill directories and support numbered multi-selection plus `a` for all detected CLIs.
- Clean the temporary clone on success and failure, and return nonzero for clone, copy, or verification failures.

---

### Task 1: Add the Matt Pocock engineering installer

**Files:**
- Create: `skills/matt-pocock-engineering.zsh`

**Interfaces:**
- Consumes: detected CLI commands and the upstream Git repository.
- Produces: installed engineering skill directories and an exit status suitable for shell automation.

- [x] **Step 1: Define the failing sandbox checks**

Create a temporary fake `HOME` and fake CLI executables plus a fake `git clone` wrapper that copies a local fixture. The checks must cover: all three detected CLIs, selecting `a`, copied engineering skills in all three destinations, no productivity skill copied, existing skill preservation, a nonzero result for clone failure, a nonzero result for a destination copy conflict, a nonzero result when verification finds a missing `SKILL.md`, and a nonzero result on closed stdin.

- [x] **Step 2: Run the checks and confirm they fail**

Run the sandbox checks against `skills/matt-pocock-engineering.zsh`; the command must fail because the installer does not exist yet.

- [x] **Step 3: Implement the installer**

Follow the structure of `skills/superpowers.zsh`:

```zsh
MATT_SKILLS_REPO="https://github.com/mattpocock/skills.git"
MATT_ENGINEERING_DIR="skills/engineering"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
OPENCODE_SKILLS_DIR="$HOME/.config/opencode/skills"
```

Implement these phases:

1. Print a purpose header and detect the three CLI commands.
2. Exit with status 1 if none are detected.
3. Present detected CLIs as a numbered menu with `a) all detected`, accept space-separated numbers, and reprompt invalid input.
4. Require `git`, create a temporary directory, and clone with `--depth 1 --quiet` into `$TMP_DIR/repository`.
5. Enumerate `"$TMP_DIR/repository/$MATT_ENGINEERING_DIR"/*/` and accept only directories containing `SKILL.md`.
6. Copy each selected skill only when its destination directory does not already exist; report copied and skipped counts.
7. Verify every enumerated engineering skill has a `SKILL.md` at each selected destination.
8. Remove the temporary directory through a cleanup function registered with `trap`, preserve the first failure status, and exit nonzero when any phase fails.
9. Print restart, update, and upstream documentation reminders.

Avoid `path` as a local variable name because it is special in Zsh. Quote all source and destination paths.

- [x] **Step 4: Run the sandbox checks and confirm they pass**

Run the same fake-`HOME` checks from Step 1. Expected results: all selected destinations contain the engineering skills, `productivity` is absent, pre-existing directories are unchanged, and clone failure returns nonzero while cleaning up.

- [x] **Step 5: Run static verification**

Run:

```sh
zsh -n skills/matt-pocock-engineering.zsh
chmod +x skills/matt-pocock-engineering.zsh
```

Expected: syntax validation succeeds and the script is executable.

---

### Task 2: Verify repository integration without adding unrelated scope

**Files:**
- Verify: `skills/matt-pocock-engineering.zsh`
- Verify: `skills/superpowers.zsh`
- Verify: `Makefile`

**Interfaces:**
- Consumes: the new standalone script.
- Produces: evidence that existing installers and repository checks remain unaffected.

- [x] **Step 1: Verify the help-free standalone entry point**

Run the new script with fake CLI commands and select `0` only if a cancellation path is implemented; otherwise select a valid target and inspect the copy summary. Confirm no repository files are modified by the installer.

- [x] **Step 2: Run existing repository checks**

Run:

```sh
make soft-test
```

Expected: the existing repository checks pass. If `soft-test` does not inspect nested `skills/*.zsh`, separately run `zsh -n skills/matt-pocock-engineering.zsh` and verify executable permissions.

- [x] **Step 3: Review the final diff**

Run:

```sh
git diff --check
git status --short
```

Confirm the only feature artifact is `skills/matt-pocock-engineering.zsh` plus this implementation plan, and do not commit unless explicitly requested.
