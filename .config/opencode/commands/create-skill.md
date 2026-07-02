---
description: Create or improve a Claude/OpenCode skill by drafting SKILL.md, writing test prompts, and iterating with the user
---

You are creating or improving a skill (a reusable prompt + frontmatter file). Drive the conversation through this loop and adapt to where the user is.

## 1. Capture intent
Ask (and extract from history if the user already described a workflow):
- What should this skill enable?
- When should it trigger? (specific user phrases / contexts)
- Expected output format?
- Should we set up test cases? (objectively verifiable outputs → yes; subjective → usually no)

## 2. Draft the SKILL.md
YAML frontmatter (required): `name`, `description`. The `description` is the **primary** triggering mechanism — include both what the skill does AND specific contexts for when to use it. Claude undertriggers skills, so make it a little **pushy** ("use this whenever the user mentions X, Y, or Z — even if they don't say 'skill'"). All "when to use" info goes in the description, not the body.

Body: imperative instructions, under ~500 lines. Explain the **why** behind steps instead of rigid MUSTs. Bundle repeated helper logic into a `scripts/` dir and reference it. For large reference files, add a table of contents.

Layout:
```
skill-name/
├── SKILL.md            (required: frontmatter + markdown)
└── (optional) scripts/ references/ assets/
```

## 3. Test prompts
Write 2–3 realistic prompts a real user would say. Share them: "Here are a few test cases — do these look right?" Then run them (with the skill, and a baseline without it if subagents are available).

## 4. Evaluate + iterate
- Qualitative: walk the user through each output; collect feedback.
- Quantitative (if testable): draft assertions, grade outputs, compute pass rates.
- Improve the skill from feedback. Generalize — don't overfit to the examples. Keep the prompt lean; cut what isn't pulling weight.
- Repeat until the user is satisfied.

## 5. Optimize the description (optional)
Generate ~20 realistic trigger-eval queries (concrete, with file paths/typos/casual speech; half should-trigger, half near-miss should-not-trigger). Review with the user, then evaluate trigger rate and iterate the description until triggering is accurate.

## Notes
- Preserve an existing skill's name when editing.
- If the user says "just vibe with me", skip the eval machinery and draft collaboratively.
- Print the final SKILL.md path so the user can install it.
