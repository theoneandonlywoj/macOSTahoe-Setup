---
name: w-to-spec
description: Materialize brainstorm decisions as approved implementation specs. Use only when the user runs /w-to-spec.
---

# Write Specs

Turn the latest `/w-brainstorm` state into approved, implementation-ready artifacts. Invoking `/w-to-spec` ends the interview and approves writing specs. Never implement code or ask another question.

## Resolve Inputs

Use the latest injected `[w-brainstorm-context]` JSON. The target argument may narrow the work or identify an existing session. If neither source identifies a topic, explain that `/w-brainstorm <topic>` must run first and stop without writing.

Resolve omitted details in this order:

1. Preserve explicit user decisions; the latest value for a stable key wins.
2. Follow repository architecture, behavior, conventions, and documentation.
3. Follow current authoritative external documentation and established practices.
4. Choose the lowest-risk reversible default.

Never silently override the user. Record each inference with its source, evidence, decision, and rationale.

## Build Artifacts

1. Parse the compact context and target.
2. Inspect relevant repository evidence. Delegate to `explore` only when discovery is genuinely independent and substantial; reconcile and verify its findings.
3. Select `technical-execution` by default, `product-requirements` for behavior-first work with flexible architecture, or `task-checklist` for procedural work.
4. Split broad work into independent features and order dependencies first.
5. Select `docs/specs/NNN-slug/`, where `NNN` is three digits and the slug matches `[a-z0-9]+(?:-[a-z0-9]+)*`. Update an explicitly selected existing session; otherwise allocate one greater than the highest valid number. Recheck before writing and never overwrite another session by slug coincidence.
6. Write `decisions.xml` and only the numbered Markdown artifacts the design needs.
7. Preserve `implemented.md`. Never create or edit it.
8. Return paths, feature statuses, inferred defaults, blockers, and `/w-implement NNN-slug` when any feature is ready.

Use safe kebab-case filenames with two-digit numeric prefixes. Every implementation feature must contain:

- `Status: ready` or `Status: blocked`.
- Scope and non-goals.
- Stable `US-NN` user stories using `As a`, `I want`, and `So that`.
- Behavioral Gherkin scenarios using `Scenario`, `Given`, `When`, and `Then`.
- Resolved behavior and contracts.
- One repository-relative path per `Affected files` entry with exactly one `created`, `updated`, or `deleted` action; never use `TBD`.
- Dependencies and unresolved prerequisites.
- Relevant errors, edge cases, compatibility, security, migration, rollout, and observability concerns.
- Observable acceptance criteria and runnable verification steps.
- Risks and rationale for non-obvious decisions.

Represent every observable acceptance criterion with at least one scenario. Keep scenarios implementation-independent and split unrelated behaviors. Mark a feature blocked only for a concrete external prerequisite or required prototype that repository evidence or a reversible default cannot resolve.

## Decisions XML

Write well-formed XML in this shape:

```xml
<decisions session="001-topic" topic="Human topic" style="technical-execution" status="written">
  <questions>
    <question number="Q1" key="scope.example" source="user">
      <prompt>Question asked.</prompt>
      <evidence>Evidence shown.</evidence>
      <recommendation>Recommended default.</recommendation>
      <user-answer>Exact user answer.</user-answer>
      <decision>Normalized decision.</decision>
    </question>
  </questions>
  <inferences>
    <inference key="errors.timeout" source="repository">
      <evidence>src/example.ts:42</evidence>
      <decision>Use the existing timeout behavior.</decision>
      <rationale>Preserves the established contract.</rationale>
    </inference>
  </inferences>
</decisions>
```

Escape XML metacharacters. Preserve exact user wording in `user-answer` and normalize it separately in `decision`. Use only `repository`, `external`, or `default` as inference sources. Set root status to `written`.

Write only under the selected session directory. Return only the concise handoff, not artifact contents.
