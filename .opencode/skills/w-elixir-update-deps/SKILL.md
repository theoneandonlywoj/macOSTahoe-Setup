---
name: w-elixir-update-deps
description: Review, select, update, verify, and document Elixir dependencies. Use when the user runs /w-elixir-update-deps.
---

# Elixir Dependency Update

Follow this workflow exactly. The workflow is interactive: discovery and
selection happen before any files are changed.

## 1. Discover Updates

1. Find the Mix project or umbrella root and read its `AGENTS.md` and relevant
   `mix.exs` files before running update commands.
2. Run `mix help hex.outdated`, then run `mix hex.outdated` from the project or
   umbrella root.
3. Classify direct dependencies from the command output:
   - **Update possible**: dependencies whose status is `Update possible`.
   - **Blocked**: dependencies whose status is `Update not possible` under the
     current version constraints.
4. Do not change files during discovery.
5. Return a normal chat message in this format and stop:

   ```text
   Dependency updates

   Update possible:
   - <package>: <current> -> <latest>

   Blocked:
   - <package>: <current> -> <latest> (blocked by current constraints)

   Reply in chat with `all` to update every package marked Update possible, or
   list specific package names separated by spaces or commas. Blocked packages
   require explicit selection and a separate constraint-change confirmation.
   ```

   Show `None` when either group is empty. Never use the `question` tool or any
   popup. If there are no possible or blocked updates, report that and stop.

## 2. Resolve Selection

1. Interpret `all` as every dependency in **Update possible** only.
2. Accept specific dependency names separated by whitespace or commas.
3. If a name was not listed, explain that it is not an available candidate and
   ask for a corrected selection in normal chat.
4. If the user selects a blocked dependency:
   - Locate every declaration and current version constraint in `mix.exs` files.
   - Explain the minimal constraint change required and any known compatibility
     concern.
   - Ask for explicit confirmation in normal chat before changing constraints.
   - Do not update any dependency until the complete selection is confirmed.
5. Treat `none`, `cancel`, or an equivalent response as cancellation and stop
   without changing files.

## 3. Protect Existing Work

1. Inspect `git status --short` before editing.
2. Never revert, overwrite, stage, or modify unrelated changes.
3. If `mix.lock` or a `mix.exs` file that must change is already modified, show
   the conflicting paths and ask in normal chat whether to continue. Do not use
   the `question` tool.
4. Track which files this workflow changes so `PR.md` can distinguish dependency
   work from pre-existing worktree changes.

## 4. Update Dependencies

1. For `all`, run `mix deps.update --all`.
2. For a specific selection, run `mix deps.update <package>...`.
3. For explicitly confirmed blocked dependencies, make only the minimal required
   version-constraint edits, then update those packages.
4. Inspect the resulting dependency resolver output and lockfile changes.
5. Record every package whose locked version changed, including transitive
   dependencies. Do not limit documentation to the originally selected direct
   dependencies.
6. For every blocked dependency that remained unchanged, identify and record:
   - Its current and latest versions.
   - The exact incompatible version constraint or dependency requirement.
   - Where that requirement comes from, such as a `mix.exs` declaration or the
     package and version that introduces a transitive constraint.
   - Why the resolver cannot select the latest version while that requirement
     remains. List every independent blocker when more than one applies.
   Use resolver output, `mix deps.tree`, lockfile metadata, and upstream package
   requirements as needed. Do not describe a dependency only as "blocked by
   current constraints."

## 5. Verify the Project

1. Use the repository's required completion command. Prefer `mix precommit` when
   the alias exists; otherwise run the most relevant compile, formatting, and
   test commands defined by the project.
2. Fix only compatibility issues caused by the dependency update.
3. Re-run verification after fixes until it passes or a concrete external
   blocker remains.
4. Record test counts, failures, warnings, and commands run. Distinguish upstream
   dependency warnings or unavailable external services from project failures.

## 6. Research Every Updated Package

For each direct or transitive package whose locked version changed:

1. Use the Hex package API (`https://hex.pm/api/packages/<package>`) to identify
   the official repository, changelog, documentation, and release metadata.
2. Prefer an upstream changelog entry covering the exact old-to-new range.
3. Otherwise use upstream releases, tags, or a tag comparison.
4. If no changelog or release notes exist, derive the changes from upstream tag
   or source differences. Label the result as derived and link the comparison,
   tags, commits, or repository used as evidence.
5. Never invent release notes or present assumptions as upstream statements.
6. Summarize only the versions crossed by this update.

## 7. Assess Project Impact

For every updated package, inspect the repository rather than relying only on
the package description:

1. Search for direct module, function, configuration, and feature usage.
2. Identify whether it is direct or transitive and which dependency pulls it in.
3. Identify its environment scope (`prod`, `dev`, `test`, or all environments).
4. Relate upstream changes to the APIs and behavior this project actually uses.
5. Write a concise `How it impacts the project` statement. State when changed
   APIs are unused or when the dependency is development-only.

## 8. Assess Upgrade Risk

Assign one integer score from 1 to 10 and explain it in one concise sentence:

- **1-2**: development-only, unused API, isolated transitive patch, security fix,
  or straightforward bug fix with no used API changes.
- **3-4**: core dependency patch/minor update with limited behavior changes or a
  certificate/trust-store update that could affect an external endpoint.
- **5-6**: meaningful runtime, configuration, persistence, or operational
  behavior changes that need targeted validation.
- **7-8**: breaking API changes, migrations, broad compatibility concerns, or
  substantial production behavior changes.
- **9-10**: high likelihood of data loss, deployment failure, production outage,
  or severe unresolved compatibility risk.

The score measures the risk of applying the upgrade, not the severity of a
vulnerability fixed by the upgrade. Mention security urgency separately.

## 9. Generate PR.md

Create or replace `PR.md` at the repository root with:

1. A concise dependency-update overview and the update command used.
2. A table containing package, old version, new version, and whether it is direct
   or transitive (including its declaring file or dependency path when known).
3. A `Per-dependency changelog summaries` section for every updated package.
4. Each dependency section must use this order:

   ```markdown
   ### `package` old -> new

   [Upstream changelog or derived comparison](https://...)

   - **How it impacts the project:** <evidence-based impact>
   - **Risk assessment:** <1-10>/10. <concise rationale>

   - <summarized release note>
   - <summarized release note>
   ```

5. A `Blocked dependencies` section when any latest version remains blocked.
   Include one subsection per dependency using this format:

   ```markdown
   ### `package` current -> latest

   - **Blocked by:** `<constraint>` from `<mix.exs path or dependent package and version>`.
   - **Reason:** <why the current requirement and latest version are incompatible>.
   - **What would unblock it:** <minimal constraint or upstream dependency change required>.
   ```

   Include every independent blocker and use concrete constraints and sources;
   never use only a generic statement such as "blocked by current constraints."
6. A `Project changes` section listing every file changed by this workflow and a
   concise description. If no application source or configuration changes were
   needed, say so explicitly.
7. A `Verification` section with commands and results.

Use ASCII punctuation in newly generated prose unless the existing file clearly
uses another convention.

## 10. Final Response

Return a concise completion summary containing:

- Updated dependencies and version ranges.
- Blocked or skipped dependencies.
- Files changed by this workflow.
- Verification result.
- The path to `PR.md`.

Never run `git commit`, `git push`, stage files, or add agent attribution.
