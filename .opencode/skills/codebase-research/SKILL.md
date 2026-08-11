---
name: codebase-research
description: Use when a user invokes /codebase-research, or asks to "research the codebase/architecture", "generate an architecture doc", "analyze the codebase", or similar. Researches the code architecture grounded in a feature Gherkin note from _woj/01-gherkin-note/, using Graphify first when the knowledge graph exists, then writes a structured analysis to _woj/02-architecture/NNN-<feature-name-slug>.md covering software patterns, gotchas, types (if applicable), and readability.
---

# Codebase Research

Research the code architecture to support a feature being designed, grounded in the corresponding Gherkin note from `_woj/01-gherkin-note/`, and write a structured analysis to `_woj/02-architecture/`. Use Graphify first whenever the knowledge graph is available; fall back to direct codebase exploration otherwise.

## When to use

- The user invokes `/codebase-research`.
- The user asks to "research the codebase", "analyze the architecture", "generate an architecture doc", or similar phrasing.
- The user passes a file path to an existing architecture note (e.g. `/codebase-research _woj/02-architecture/002-...md <conclusions>`), or asks to "update the architecture note with conclusions", "append conclusions". This is **update mode** — see "Workflow (update mode)".

Always review `AGENTS.md` (if present) and `docs/` as the source of truth before researching, regardless of mode.

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/02-architecture/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it names a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Review AGENTS.md and docs/ (source of truth)

- Read `AGENTS.md` at the repo root if present. It defines project conventions and rules (e.g. knowledge-graph usage, skip policies) that the research must respect and repeat.
- Read the `docs/` directory listing and open the relevant guides. Docs are the source of truth for how the project is intended to work; do not contradict them.
- If the task is about stale or incorrect graph output, or the user explicitly says not to use Graphify, skip the graph and go to step 5.

### 2. Determine the research scope from the Gherkin note

- Locate the feature note in `_woj/01-gherkin-note/`. If the user named one, use it. Otherwise use the note with the highest `NNN-` prefix (the latest feature).
- Read the note in full: `Source`, `Assumptions`, `Open questions`, `Feature`, `Background`, and `Scenarios` tell you which actors, behaviors, and edge cases the feature must serve. Note any `Conclusions` appended by follow-up questions.
- If no Gherkin note exists, fall back to a whole-codebase overview.

### 3. Use Graphify first when available

Check that Graphify is available: the `graphify` binary is on PATH (`which graphify`) and `graphify-out/graph.json` exists. If either is missing, go to step 5.

- **Freshness check:** compare `git rev-parse HEAD` to the commit the graph was built from (read it from `graphify-out/GRAPH_REPORT.md`). If the graph is stale, or `graph.json` is missing, run `graphify update .` (AST-only, no API cost) before querying.
- Drive the research with focused Graphify commands rather than grepping raw files:
  - `graphify query "<question>"` — fetch a scoped subgraph around the feature's concepts.
  - `graphify path "<A>" "<B>"` — find relationships between two modules/concepts.
  - `graphify explain "<concept>"` — plain-language explanation of a node.
- Use `graphify-out/GRAPH_REPORT.md` only for broad architecture context (god nodes, communities, import cycles, knowledge gaps).
- If `graphify-out/wiki/index.md` exists, use it for broad navigation before raw source browsing.
- Use the surfaced subgraph to decide which source files to open next; prefer the returned `src=... loc=L<line>` references for precise navigation.

### 4. Deep-read the grounded sources

- Open the files and line ranges surfaced by the subgraph, plus any files named by the Gherkin note's scenarios.
- Record concrete `file:line` references for everything you cite.

### 5. Fallback when Graphify is unavailable

- Explore directly: catalog the layout (`ls`/Glob), then read, in order of trust: `AGENTS.md`, `docs/`, `README.md`, the `Makefile` or build config, then the source files and scripts that the feature touches.
- Follow existing conventions and patterns; note where the code deviates from them.

### 6. Write the architecture note

Write to `_woj/02-architecture/NNN-<feature-name-slug>.md` where:

- `NNN` and `<feature-name-slug>` **mirror the source Gherkin note's basename** (e.g. Gherkin note `_woj/01-gherkin-note/002-setup-logging.md` produces `_woj/02-architecture/002-setup-logging.md`), making the pair traceable.
- When there is no Gherkin note, scan `_woj/02-architecture/*.md` for the highest existing `NNN-` prefix, add 1, and zero-pad to 3 digits (start at `001` if empty). Use a kebab-case slug of the research subject.

Create `_woj/02-architecture/` if it does not exist. Never overwrite an existing file — the sequence number guarantees uniqueness.

Use the template below. A note is Markdown; all fenced blocks use triple backticks. **Drop sections that add no value** (`Types`, `Assumptions`, `Open questions`) rather than leaving them empty.

### 7. Note template

    # <Short imperative title>

    ## Source

    > <the request, verbatim>

    Feature note: `_woj/01-gherkin-note/NNN-<feature-name-slug>.md`

    ## Overview

    <how the relevant part of the codebase is architected, at the level the feature needs>

    ## Software patterns

    - <pattern / idiom observed, with `file:line`>

    ## Gotchas

    - <non-obvious trap or pitfall, with `file:line`>

    ## Types

    <data shapes, config/environment contracts, or type signatures that cross the feature's path — only if applicable>

    ## Readability

    <naming, cohesion, module size, and documentation coverage of the areas touched: what is easy to follow, what is hard>

    ## Assumptions

    - <assumption you had to make>

    ## Open questions

    - <unresolved item>

Section guidance:

- **Software patterns** — recurring idioms and shapes: per-tool `*.zsh` convention, Makefile targets, plugin/hook structure, configuration-over-convention patterns, error-handling style. Back each with `file:line`.
- **Gotchas** — non-obvious traps: stale graph vs HEAD, macOS-specific quirks, ordering dependencies, magic names or env vars, differences between docs and implementation.
- **Types** — only when the codebase carries typed contracts (config schemas, structs/typespecs, JSON shapes, env-var contracts). When the codebase is untyped, omit the section entirely.
- **Readability** — how navigable the touched code is: consistent naming, cohesive boundaries, file length, docstring/comment coverage, how quickly a new person can trace the feature through it.

### 8. Verify before finishing

- Re-read the written file and confirm the filename mirrors the source Gherkin note (`NNN-<slug>.md`).
- Confirm each section's claims carry accurate `file:line` references.
- Confirm assumptions and open questions from step 2 actually made it into the note, and that the source-of-truth review (step 1) is reflected.

## Workflow (update mode)

When a file path to an existing architecture note is provided:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/02-architecture/`.
- Confirm the file exists and is an architecture note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not an architecture note (no `# ` title with the expected sections), report the mismatch and ask the user to confirm before editing.

### 2. Extract the follow-up conclusions

- Take the remaining arguments as the follow-up conclusions (if any were supplied). Preserve them verbatim as list items, one per conclusion.
- If no conclusions were supplied but the user referenced a prior discussion, derive them from that context; otherwise note in the Conclusions section that no conclusions were recorded yet.

### 3. Append the Conclusions section

- Re-read `AGENTS.md` and `docs/` per step 1 of create mode, then read the existing note and append a `## Conclusions` section at the end.
- If the note already has a `## Conclusions` section, do not overwrite it — append the new conclusions to it, preserving the earlier ones.
- Format:

    ## Conclusions

    - <conclusion>
    - <conclusion>

- Leave all existing sections unchanged.
- If a conclusion resolves an item previously listed under `## Open questions`, append the conclusion and optionally strike through the resolved question (e.g. `- ~~<resolved item>~~`), leaving the question text in place.

### 4. Verify before finishing

- Re-read the file and confirm the original content is untouched and only `## Conclusions` (or its existing section) gained the new items.
- Confirm conclusions are stored as a list under `## Conclusions`.

## Reporting back

- **Create mode:** tell the user the file created (full path) and summarize the key patterns, gotchas, and readability findings in a few lines. Surface any assumptions or open questions in one or two lines so the user can correct the note if needed.
- **Update mode:** tell the user which file was updated (full path) and summarize the conclusions appended. If any open questions were resolved and struck through, mention them.