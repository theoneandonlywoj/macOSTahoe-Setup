# Question format (always identical)

Every question, without exception, uses this shape. Yes/No questions included.

```
Q<question number>(<area>): <question>
1. <option 1> (Recommended) - <short explanation, 1-2 gist sentences>
2. <option 2> - <short explanation, 1-2 gist sentences>
...

Recommended: <explanation why this is the recommended option>
Caveats: <short 1-3 sentence explanation why another option might be a valuable alternative>
```

Rules:

- `<question number>` increments across the whole session (`Q1`, `Q2`, `Q3`, ...).
- `<area>` is a short tag from the question catalog (e.g. `scope`, `actors`, `edge-cases`).
- The recommended option is always listed **first** and always marked `(Recommended)`.
- Every option carries a 1-2 sentence plain-language explanation of its gist.
- `Recommended:` must explain why that option is the right pick for this feature.
- `Caveats:` must note, in 1-3 sentences, when a non-recommended option would be the better choice.
- Yes/No questions follow the same format:

```
Q4(yes-or-no): Should the tool auto-install Homebrew if missing?
1. Yes (Recommended) - Auto-install keeps first-run friction to zero and matches the doc's bootstrap intent.
2. No - Fail with a clear message so the user keeps control over system mutations.

Recommended: Yes, because the feature goal is a single-command setup and the install step is already scripted elsewhere in the repo.
Caveats: No is valuable in locked-down environments or CI where unilaterally installing system packages is unacceptable.
```
