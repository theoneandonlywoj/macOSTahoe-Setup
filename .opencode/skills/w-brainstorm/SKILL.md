---
name: w-brainstorm
description: Interview a rough idea one question at a time. Use only when the user runs /w-brainstorm.
---

# Brainstorm

Interrogate a rough idea until it is implementation-ready. Never implement it or write files. `/w-to-spec` is the only way to end the interview and materialize specs.

## Protocol

1. Research repository and external facts with targeted, parallel tool calls. Do not ask for discoverable facts or repeatedly research settled topics.
2. Ask exactly one question in each response, then wait for a normal chat reply. Never use the `question` tool.
3. Ask for intent, decisions, priorities, constraints, and ambiguous tradeoffs. Challenge vague language, hidden assumptions, contradictions, unnecessary complexity, and missing failure behavior.
4. Recommend one concrete default with its main reason. Never treat the recommendation as the user's answer.
5. Continue until `/w-to-spec` runs. When the design appears complete, ask about the highest-value remaining stress case or revision.

Cover objective and users, journeys and scenarios, scope and non-goals, observable behavior, interfaces and data, errors and recovery, security and permissions, compatibility and migration, performance, observability, rollout, affected files, acceptance criteria, and tests when relevant. Split broad work into independently implementable features and identify dependencies, prototype needs, and external blockers.

## Question Format

Return only this block, with each field on one physical line:

```text
Q<number> [<decision-key>]
Evidence: <concise repository or external evidence, or "None yet.">
Recommendation: <one concrete default and its main reason>
Question: <one question only; concise options may be included inline>
```

- Start at `Q1` and increase globally within the brainstorm.
- Use a stable lowercase key matching `[a-z0-9]+(?:[.-][a-z0-9]+)*`.
- Add a decision with a new key. Replace that decision in compact context when reusing its key.
- Preserve exact paths, symbols, commands, limits, and user terminology when relevant.
- Accept free-text answers.

The context plugin injects `[w-brainstorm-context]` with the topic, settled decisions, and latest unanswered question. Treat it as the authoritative compact state. If the topic is empty, ask for it as `Q1 [topic]`; otherwise research enough to ask the first material decision question.

Do not summarize, approve, write a handoff, or mention another stop phrase.
