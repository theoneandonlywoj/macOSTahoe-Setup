# Woj OpenCode Workflow

This repository defines a project-local OpenCode workflow for turning a rough idea into reviewed code:

```text
/w-brainstorm -> /w-to-spec -> /w-implement -> /w-commit
```

The workflow separates interviewing, specification, implementation, and commit preparation so each stage has narrowly scoped permissions and a clear handoff. Standalone commands, including Playwright test generation, are documented separately and are not extra stages in this sequence.

## Quick Reference

| Command | Responsibility | Writes files? |
| --- | --- | --- |
| `/w-brainstorm <topic>` | Ask one repository-informed design question at a time | No |
| `/w-to-spec [target]` | End brainstorming and materialize approved specs | Only `docs/specs/**` |
| `/w-implement [target]` | Implement ready specs and verify the result | Yes |
| `/w-commit` | Propose a commit message and copyable command from staged changes | No |

OpenCode loads agents, commands, and plugins at startup. Restart OpenCode after changing files under `.opencode/`.

## Standalone Playwright Test Generation

Use the one-shot Playwright command independently of the four-stage spec workflow:

```text
/w-playwright-gen-test <http(s)-url> <scenario>
```

Example:

```text
/w-playwright-gen-test https://demo.playwright.dev/todomvc add a todo named Buy groceries and verify it appears
```

The command runs directly under its restricted agent (`subtask: false`) so its redacted result is not rephrased by a parent agent. It preflights the target project, explores the safe flow through an ephemeral `playwright-cli` session, creates one collision-safe TypeScript spec, runs only that file with the project's local `@playwright/test`, and makes at most two evidence-based repairs. The fixed limit is **3 total test executions**.

### Prerequisites and supported scope

- Node.js 20 or newer and `playwright-cli`; run `./playwright_cli.zsh` or follow the [first-party installation guide](https://playwright.dev/agent-cli/installation).
- An unambiguously detected npm, pnpm, Yarn, or Bun target project with project-local `@playwright/test` and a discoverable `playwright.config.*`.
- A reachable absolute HTTP(S) URL and a non-empty, non-consequential public or local scenario.

Preflight happens before browsing or file creation. The command does not scaffold tests, install project dependencies, edit config/application/support files, or overwrite existing specs. It rejects credential-bearing URLs and sensitive query values without echoing them. Authentication, saved state, SSO/MFA/CAPTCHA, uploads/downloads, visual-only checks, privileged browser permissions, and consequential remote mutations are blockers.

Live page and runner content are untrusted data. The command does not collect screenshots, video, traces, storage state, response bodies, or full network headers by default. It always attempts to close its named browser session and reports status, generated path or `no file written`, execution count, repairs, cleanup, blocker/failure, the exact next action, and whether the test depends on a live external target.

See [guide_playwright_tests.md](guide_playwright_tests.md#autonomous-test-generation) for the authoritative generation and safety policy.

## 1. Brainstorm

Start an interview with a topic that is specific enough to research:

```text
/w-brainstorm add automatic Homebrew cleanup
```

If the topic is omitted, the first question asks for it.

`/w-brainstorm` runs in the current OpenCode session because its command sets `subtask: false`. It asks exactly one question in a normal assistant message and then returns control. Answer normally to continue:

```text
Q3 [cleanup.retention]
Evidence: Existing backup scripts retain every timestamped backup.
Recommendation: Retain the newest three backups to preserve rollback options without unbounded growth.
Question: How many backups should cleanup retain?
```

Normal messages are intentional. OpenCode's `question` tool blocks inside a running agent loop, which would prevent `/w-to-spec` from being invoked as the next slash command.

### Interview behavior

The brainstorm agent:

- Reads repository code and documentation before asking factual questions.
- Asks for user intent, tradeoffs, constraints, priorities, and ambiguous behavior.
- Challenges vague requirements, contradictions, hidden assumptions, and missing failure behavior.
- Covers scope, non-goals, interfaces, data, errors, security, compatibility, migration, performance, observability, rollout, affected files, acceptance criteria, and tests when relevant.
- Never edits files or implements the feature.
- Continues asking questions until `/w-to-spec` is invoked.

There is no separate finish phrase. Run `/w-to-spec` instead of answering the current question when enough decisions have been explored.

### Stable decision keys

Every question has a stable key such as `cleanup.retention`. A new key adds a decision to compact context. Reusing a key replaces its previous value in compact context while leaving the original exchange visible in the stored transcript.

Keys use this form:

```text
[a-z0-9]+(?:[.-][a-z0-9]+)*
```

Question numbers increase globally within the brainstorm. The context plugin records the latest question number so compaction does not reset numbering.

## 2. Generate Specs

Run `/w-to-spec` in the same OpenCode session:

```text
/w-to-spec
```

It can also receive an explicit existing session when revising specs:

```text
/w-to-spec 003-homebrew-cleanup
```

Invoking `/w-to-spec` has three meanings:

1. End the active brainstorm.
2. Approve writing specification artifacts.
3. Allow the spec agent to infer unanswered details without another interview.

The spec agent resolves missing information in this order:

1. Explicit user decisions, with the latest value for a stable key winning.
2. Existing repository architecture, behavior, conventions, and documentation.
3. Current authoritative external documentation and established best practices.
4. The lowest-risk reversible default.

Inferred choices are recorded with their source, evidence, and rationale. An unanswered final brainstorm question does not block generation by itself.

### Spec artifacts

New sessions use the next available three-digit number:

```text
docs/specs/NNN-topic/
|-- decisions.xml
|-- 01-feature-a.md
|-- 02-feature-b.md
|-- 03-prototype-brief.md
`-- 04-blocked-feature.md
```

Only required files are created. Each implementation feature includes:

- A `ready` or `blocked` status.
- Scope and non-goals.
- User stories written as `As a <role>`, `I want <capability>`, `So that <benefit>`.
- Gherkin scenarios covering relevant happy paths, errors, edge cases, permissions, migrations, and recovery behavior.
- Resolved behavior and contracts.
- Exact affected paths marked `created`, `updated`, or `deleted`.
- Dependencies and unresolved prerequisites.
- Relevant edge cases, errors, compatibility, security, migration, rollout, and observability concerns.
- Observable acceptance criteria and runnable verification steps.
- Risks and rationale for non-obvious decisions.

User stories use stable identifiers and behavioral scenarios:

````markdown
## User Stories

### US-01: Retain recent backups

As a setup maintainer,
I want cleanup to retain recent backups,
So that I can recover from a bad configuration change.

#### Scenario: Remove backups beyond the retention limit

```gherkin
Given five timestamped backups exist
And the retention limit is three backups
When cleanup runs
Then the three newest backups remain
And the two oldest backups are removed
```
````

Scenarios describe externally observable behavior rather than implementation details. Every observable acceptance criterion must be represented by at least one scenario.

`decisions.xml` has root status `written`, because invoking `/w-to-spec` is approval. Its root `style` attribute is inferred as `technical-execution`, `product-requirements`, or `task-checklist`.

`/w-to-spec` never edits `implemented.md`; that file belongs to `/w-implement`.

## 3. Implement

Implement an entire ready session:

```text
/w-implement 003-homebrew-cleanup
```

Run `/w-implement` without arguments to use its session picker, or pass an explicit feature path to narrow the run.

The implementation agent:

- Requires `decisions.xml` status `written`.
- Implements only feature files marked `ready`.
- Requires user stories and Gherkin scenarios, then uses their `Given`, `When`, and `Then` clauses as implementation and verification inputs.
- Resolves dependencies before implementation.
- Treats spec files as read-only.
- Limits normal edits to each feature's `Affected files` contract plus minimal adjacent integration changes.
- Runs acceptance criteria and repository-specific checks.
- Records outcomes and spec fingerprints in `implemented.md`.
- Never stages or commits changes.

A changed feature spec or `decisions.xml` changes its fingerprint, making the feature eligible for implementation again.

## 4. Prepare a Commit

Review and stage the desired changes, then run:

```text
/w-commit
```

`/w-commit` reads staged changes and returns a commit proposal with the affected files, commit message, and complete copyable `git commit` command. It never executes the commit.

## Token-Efficient Context

Long interviews normally become expensive because each model request replays the growing conversation. The project-local plugin at `.opencode/plugins/w-brainstorm-context.ts` reduces that cost through OpenCode's `experimental.chat.messages.transform` hook.

The plugin:

- Leaves the complete raw interview stored and visible in the OpenCode session.
- Reconstructs canonical state from formatted questions and normal user answers.
- Keeps only the latest answer for a repeated stable decision key.
- Sends the model the topic, canonical decisions, latest unanswered question, and active turn.
- Removes older Q&A and old research tool output only from the model-bound view.
- Injects the same canonical state into `/w-to-spec`.
- Fails open, allowing the unmodified conversation through if transformation fails.

This makes model context proportional to the current resolved design rather than the full historical interview. It is not strictly constant: genuinely distinct decisions and long answers still increase context because the final specification needs that information.

The spec agent refreshes repository and external evidence instead of depending on verbose research output from earlier brainstorm turns.

## What `steps: 8` Means

The brainstorm agent declares:

```yaml
steps: 8
```

`steps` limits model and tool iterations for one user message. A typical sequence is:

1. The model evaluates the answer.
2. It calls `grep`, `read`, `webfetch`, or another allowed research tool.
3. OpenCode returns the tool result.
4. The model continues in another step.

At the limit, OpenCode forces a text response instead of allowing an unbounded tool loop.

The limit does not mean eight questions or eight total interview turns. It resets for every normal user answer. In this workflow, it protects each individual question from excessive research while allowing the overall brainstorm to continue for as long as needed.

## Session Mechanics

`/w-brainstorm` and `/w-to-spec` both set `subtask: false`. Their messages therefore share one root-session history, and the context plugin can hand the latest brainstorm state directly to the spec agent.

Use `/w-to-spec` in the session containing the brainstorm. Starting an unrelated new session does not carry the interview state automatically. If OpenCode is restarted, resume the original persisted session before running `/w-to-spec`.

`/w-implement` remains a separate implementation subagent. It does not need the interview transcript because `docs/specs/` is its durable handoff.

## Configuration Files

| Path | Purpose |
| --- | --- |
| `.opencode/agents/w-brainstorm.md` | Read-only, one-question interview behavior |
| `.opencode/commands/w-brainstorm.md` | Same-session brainstorm command and start marker |
| `.opencode/plugins/w-brainstorm-context.ts` | Canonical state reconstruction and token pruning |
| `.opencode/agents/w-to-spec.md` | Research, inference, and spec-writing contract |
| `.opencode/commands/w-to-spec.md` | Same-session stop-and-materialize command |
| `.opencode/agents/w-implement.md` | Ready-spec implementation and verification |
| `.opencode/commands/w-implement.md` | Implementation target selection |
| `.opencode/skills/w-commit/SKILL.md` | Commit proposal format |
| `.opencode/commands/w-playwright-gen-test.md` | Passes the URL and scenario unchanged to the restricted agent for one-shot execution |
| `.opencode/agents/w-playwright-gen-test.md` | Hidden bounded agent with narrow browser, runner, and new-spec permissions |
| `.opencode/skills/w-playwright-gen-test/SKILL.md` | Preflight, safe exploration, generation, repair, cleanup, and handoff contract |

The existing `Makefile` `.opencode` synchronization copies all three Playwright command files without a Makefile change. Restart OpenCode after synchronization because command, agent, and skill definitions load at startup.

## Troubleshooting

### `/w-to-spec` cannot find the brainstorm

Confirm that it is running in the same OpenCode session as `/w-brainstorm`. The command needs either injected brainstorm context or a target argument that identifies the topic.

### Question numbering or decisions appear stale

Restart OpenCode after changing `.opencode` files. Agent and plugin configuration is loaded at startup and is not hot-reloaded.

### Validate the loaded configuration

Run:

```zsh
opencode debug config
opencode debug agent w-brainstorm
opencode debug agent w-to-spec
opencode debug agent w-playwright-gen-test
```

The resolved commands should show `subtask: false` for both `/w-brainstorm` and `/w-to-spec`.

### `/w-playwright-gen-test` stops before writing

Read its concise `Blocker/Failure` and `Next` fields. Confirm Node.js 20+, `playwright-cli --version`, a single detectable package manager, local `@playwright/test`, and a root Playwright config. Run `opencode debug config` and `opencode debug agent w-playwright-gen-test` after synchronizing, then restart OpenCode. Do not enable broad page/network logging or add credentials to the URL to diagnose the command.
