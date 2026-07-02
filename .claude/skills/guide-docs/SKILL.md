---
name: guide-docs
description: "Create or improve step-by-step topic guides as Markdown files under docs/. Use this whenever the user asks for a guide, tutorial, walkthrough, how-to, learning path, setup notes, explainer, or documentation page for a topic — especially when they mention docs/, guide_*.md, code examples, topic examples, diagrams, graphs, Mermaid, or want the result written to a file. Prefer using this even if the user only casually says 'make me a guide' or provides the topic/context inline without saying 'skill'."
user-invocable: true
disable-model-invocation: false
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash"]
---

# /guide-docs

Create a practical step-by-step guide for the topic and context the user provides, then write it to `docs/` with a descriptive filename that starts with `guide_` and ends in `.md`.

## Workflow

1. Clarify only the missing essentials. If the user did not provide a topic, audience, or target environment and the guide would be vague without it, ask one short question. Otherwise proceed with reasonable defaults and state them briefly.
2. Inspect existing docs before writing. Match the repository's documentation style, heading depth, code fence language tags, and level of detail where it helps consistency.
3. Put any temporary drafts, scratch notes, generated samples, or evaluation artifacts in the repository-local `tmp/` directory. Keep `docs/` for final guide files only.
4. Choose a filename in the form `docs/guide_<descriptive-slug>.md`. Use lowercase words separated by underscores, avoid vague names like `guide_notes.md`, and do not overwrite an existing guide unless the user asked to update it.
5. Write the guide as Markdown with a clear learning path:
   - Title and one-sentence purpose.
   - Short prerequisites or assumptions.
   - Table of contents for longer guides.
   - Step-by-step sections with commands, code, configuration, or topic examples.
   - Verification steps so the reader knows each major step worked.
   - Troubleshooting or common mistakes when useful.
   - Quick reference or next steps at the end.
6. Include examples that fit the user's context. Prefer concrete commands, snippets, config files, terminal output, API payloads, or before/after topic examples over generic prose.
7. Use diagrams only when they clarify a workflow, architecture, state machine, sequence, or relationship. Any graph or diagram must be a fenced Mermaid block, for example:

   ```mermaid
   flowchart TD
     A[Start] --> B[Run command]
     B --> C{Works?}
     C -- Yes --> D[Continue]
     C -- No --> E[Check troubleshooting]
   ```

8. Keep the guide self-contained but not bloated. Link to existing repo files when relevant instead of duplicating large content.
9. After writing, read back the created or modified file enough to catch formatting mistakes, broken heading order, missing code fence closers, and non-Mermaid diagrams.
10. Report the final path and summarize the guide's scope in one or two sentences.

## Guide Quality Bar

Good guides reduce uncertainty for a real reader. Each step should explain what to do, why it matters, and what success looks like. If a step can fail, include the most likely recovery path.

Prefer this shape for procedural topics:

```markdown
# [Topic] Guide

[Purpose sentence.]

## Prerequisites

## Table of Contents

## Step 1: [Outcome]

### Example

### Verify

## Step 2: [Outcome]

## Troubleshooting

## Quick Reference
```

Prefer this shape for conceptual topics:

```markdown
# [Topic] Guide

[Purpose sentence.]

## Mental Model

## Core Concepts

## Worked Example

## Common Patterns

## Mermaid Diagram

## Practice Prompts or Exercises

## Quick Reference
```

## Filename Examples

- Topic: "Docker Compose for Phoenix and Postgres" -> `docs/guide_docker_compose_phoenix_postgres.md`
- Topic: "OAuth PKCE flow" -> `docs/guide_oauth_pkce_flow.md`
- Topic: "tmux panes and sessions" -> `docs/guide_tmux_panes_sessions.md`

## Notes

- If the user explicitly names a target file, use it only if it lives under `docs/` and starts with `guide_`; otherwise explain the naming convention and choose a compliant path.
- If the guide depends on uncertain facts, mark them as assumptions or ask before writing when guessing would be misleading.
- For update requests, preserve useful existing content and improve structure, examples, diagrams, and verification rather than rewriting for its own sake.
