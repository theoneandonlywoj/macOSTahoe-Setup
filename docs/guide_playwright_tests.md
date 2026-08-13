# Playwright Test — Agent Guide

Reference for generating end-to-end test scripts with **Playwright Test** (`@playwright/test`). It runs across Chromium, Firefox, and WebKit with full browser isolation, auto-waiting, and web-first assertions. Use this guide whenever you are asked to write or extend Playwright tests.

---

## Table of Contents

1. [Setup](#setup)
2. [Project Structure](#project-structure)
3. [Anatomy of a Test](#anatomy-of-a-test)
4. [Locators](#locators)
5. [Actions](#actions)
6. [Web-First Assertions](#web-first-assertions)
7. [Waiting, Retries & Timing](#waiting-retries--timing)
8. [Advanced: Dialogs, Downloads, Network, Multi-Page](#advanced)
9. [Screenshots, Video & Trace](#screenshots-video--trace)
10. [Configuration](#configuration)
11. [Running Tests](#running-tests)
12. [Agent Conventions & Checklist](#agent-conventions--checklist)
13. [Troubleshooting](#troubleshooting)

---

## Setup

```bash
npm init playwright@latest        # scaffold a project (installs @playwright/test, creates playwright.config.ts and tests/)
npx playwright install             # download browsers (Chromium, Firefox, WebKit)
npx playwright install chromium    # only one browser
```

Manual setup:

```bash
npm i -D @playwright/test
npx playwright install
```

Everything below assumes the project has `@playwright/test` installed and a `playwright.config.ts` at the repo root.

---

## Project Structure

```
playwright.config.ts        # testDir, baseURL, projects/browsers, reporters, artifacts
tests/
  login.spec.ts             # one file per feature/flow
  checkout.spec.ts
test-results/               # generated: screenshots, videos, traces (per test)
playwright-report/          # generated: HTML report (playwright show-report)
```

- Test files use the `.spec.ts` suffix.
- One spec file per feature/flow; keep tests independent and short.
- Fixtures/helpers live in `tests/fixtures/` or `tests/support/`.

---

## Anatomy of a Test

```ts
import { test, expect } from '@playwright/test';

test('user can log in', async ({ page }) => {
  await page.goto('/login');                       // baseURL from config, so relative paths work
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('secret');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
});
```

Rules:

- **Always import from `@playwright/test`** — never from `playwright`.
- Use `page.goto('/path')` (relative) whenever `baseURL` is configured in `playwright.config.ts`.
- Each `test()` gets a **fresh browser context** — full isolation by default. State does not leak between tests. Do not clean up after yourself; isolation is automatic.
- Use `test.beforeEach` / `test.afterEach` for shared setup, `test.describe` to group tests in a file:

```ts
test.describe('checkout', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/cart');
  });

  test('shows empty cart message', async ({ page }) => {
    await expect(page.getByText('Your cart is empty')).toBeVisible();
  });
});
```

- The `page` fixture is the most common; others: `context`, `request`, `browser`, `browserName`, `isMobile`, `testInfo`. Workers/parallelism are automatic — never hardcode ports or serial file dependencies.

---

## Locators

Prefer locators in this priority order — they are resilient to DOM restructure and play well with auto-waiting:

1. **`getByRole(name)`** — best for interactive elements: `getByRole('button', { name: 'Submit' })`, `getByRole('link', { name: 'Docs' })`, `getByRole('heading', { name: 'Installation' })`, `getByRole('textbox', { name: 'Email' })`, `getByRole('dialog')`, `getByRole('menuitem', { name: 'Save' })`.
2. **`getByLabel(name)`** — form fields with `<label>`/`aria-label`.
3. **`getByPlaceholder(text)`** — input placeholder.
4. **`getByText(text)`** — non-interactive text: `getByText('Price: $10')`.
5. **`getByTitle(text)`**, **`getByAltText(text)`** — title/alt attributes.
6. **`getByTestId(id)`** — app exposes stable `data-testid` attributes (convention: convention-driven, e.g. `data-testid="checkout-button"`).
7. **CSS / XPath** — last resort only.

Chaining & filtering (preferred over complex CSS):

```ts
const row = page.getByRole('row').filter({ hasText: 'Woj' });
await row.getByRole('button', { name: 'Delete' }).click();

const dialog = page.getByRole('dialog');
await dialog.getByRole('button', { name: 'Confirm' }).click();
```

Notes:

- Locators are **lazy**: they describe a query and resolve on action/assertion.
- **Strict mode** is on by default — a locator resolving to more than one element throws. `first()`, `last()`, or `.nth(i)` when intentional.
- Never use `$`, `$$`, or `locator.evaluate` to click/fill; use the locator API.
- `data-testid` is the accepted convention for elements that need stable hooks.

---

## Actions

```ts
await page.goto('/path');                      // navigate (auto-waits for load)
await page.reload();                            // reload
await page.goBack(); / await page.goForward();
await locator.click();                          // click (auto-waits for actionability)
await locator.dblclick();
await locator.fill('text');                     // inputs/contenteditable (clears first)
await locator.pressSequentially('text');        // type, character by character
await locator.press('Enter');                   // keyboard: 'Enter', 'Tab', 'Escape', 'Control+A'
await locator.check(); / .uncheck();            // checkboxes/radios
await locator.selectOption('value');            // <select>: by value | label | index
await locator.selectOption({ label: 'Option A' });
await locator.setInputFiles('path/to/file.png');// file upload (also array / { name, mimeType, buffer })
await locator.hover();
await locator.dragTo(target);                   // HTML5 drag & drop
await locator.focus();
await page.keyboard.press('Escape');
await page.mouse.click(x, y);
```

All actions wait for the element to be **visible, stable, enabled and attached** (actionability) — no manual `waitFor` needed.

Multi-tab / frames:

```ts
const [newPage] = await Promise.all([
  page.waitForEvent('popup'),
  page.getByRole('link', { name: 'External' }).click(),
]);
await newPage.waitForLoadState();

const frame = page.frameLocator('iframe[name="chat"]');
await frame.getByLabel('Message').fill('hi');
```

---

## Web-First Assertions

Assertions **auto-retry** until the condition is met (default timeout 5s in the config). Always assert with `expect` on locators/pages — never `expect(locator.something)` on a plain value that was read once.

```ts
await expect(page).toHaveTitle(/Playwright/);
await expect(page).toHaveURL(/\/login$/);

await expect(locator).toBeVisible();
await expect(locator).toBeHidden();
await expect(locator).toBeEnabled();
await expect(locator).toBeDisabled();
await expect(locator).toBeChecked();
await expect(locator).toHaveText('exact text');            // or /regex/
await expect(locator).toHaveText([/art ./i, 'text']);       // list
await expect(locator).toHaveValue('some value');
await expect(locator).toHaveAttribute('href', /\/docs/);
await expect(locator).toHaveCount(3);
await expect(locator).toHaveJSProperty('scrollTop', 0);
await expect(locator).toBeFocused();
await expect(locator).toBeInViewport();
await expect(locator).toHaveScreenshot();                  // visual snapshot (see below)
```

Soft assertions (continue on failure):

```ts
await expect.soft(locator).toBeVisible();
```

Generic polling:

```ts
await expect.poll(async () => page.locator('tbody tr').count(), { timeout: 10_000 }).toBeGreaterThan(0);
await expect(async () => await apiCall()).toPass({ timeout: 15_000 });
```

---

## Waiting, Retries & Timing

- **Don't add sleeps.** Auto-waiting covers navigation, actionability, and assertions. `page.waitForTimeout()` is only a debugging crutch — avoid in committed tests.
- If a condition has no assertion, use `locator.waitFor({ state: 'visible' })` / `page.waitForEvent(...)` / `page.waitForLoadState()`.

```ts
await page.getByText('Loading…').waitFor({ state: 'hidden' });
```

- Flaky tests: fix the selector/wait, don't mask with retries. If needed, `retries` belongs in `playwright.config.ts`, not per-test.
- Parameterize data with arrays + `for...of` when writing the same flow for multiple inputs. Skip with `test.skip()` conditionally, or mark `test.fixme()` for known-broken.

```ts
for (const email of ['a@x.io', 'b@x.io']) {
  test(`accepts ${email}`, async ({ page }) => { ... });
}
```

---

## Advanced

### Dialogs & alerts

```ts
page.on('dialog', dialog => dialog.accept());     // or dialog.dismiss()
await page.getByRole('button', { name: 'Delete' }).click();
```

### Downloads

```ts
const downloadPromise = page.waitForEvent('download');
await page.getByRole('link', { name: 'Export' }).click();
const download = await downloadPromise;
await download.saveAs('exports/' + download.suggestedFilename());
```

### Network mocking / interception

```ts
await page.route('**/api/pricing*', route => route.fulfill({ json: { price: 0 } }));
await page.route('**/analytics/**', route => route.abort());

const responses: string[] = [];
page.on('response', res => { if (res.url().includes('/api/')) responses.push(res.url()); });
```

### API calls without a browser page

```ts
import { test, expect, request } from '@playwright/test';

test('api smoke', async () => {
  const api = await request.newContext({ baseURL: 'https://api.example.com' });
  const res = await api.get('/health');
  expect(res.ok()).toBeTruthy();
});
```

### Local dev server

`webServer` in `playwright.config.ts` boots the app before tests; tests then use `baseURL`. Never start servers inside a test.

---

## Screenshots, Video & Trace

Artifacts are controlled through `playwright.config.ts`, per-run via the env vars `SCREENSHOT`, `VIDEO`, `TRACE`, or the `--trace` CLI flag. Output lands in `test-results/<test-name>/`.

### SCREENSHOT options

| Value | Effect |
|---|---|
| `off` | no screenshots (default) |
| `on` | screenshot at every step of every test |
| `only-on-failure` | screenshot only when a test fails (saved on failure) |

Run: `SCREENSHOT=on playwright test`

### VIDEO options

| Value | Effect |
|---|---|
| `off` | no video recording (default) |
| `on` | record video of every test, keep all |
| `retain-on-failure` | record but only keep videos of failed tests |
| `on-first-retry` | record only on the first retry of a failed test |

Run: `VIDEO=retain-on-failure playwright test`

### TRACE options

Trace captures DOM snapshots, network calls, console logs, and actions.

| Value | Effect |
|---|---|
| `off` | no trace (default) |
| `on` | trace every test, keep all |
| `retain-on-failure` | trace every test but only keep traces of failures |
| `on-first-retry` | trace only on the first retry of a failed test |

Run: `playwright test --trace on`

### Combined run

```bash
SCREENSHOT=only-on-failure VIDEO=retain-on-failure TRACE=on-first-retry playwright test
```

### Config wiring

```ts
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  use: {
    screenshot: process.env.SCREENSHOT || 'off',
    video: process.env.VIDEO || 'off',
    trace: process.env.TRACE || 'off',
  },
});
```

### Extended object forms

```ts
use: {
  screenshot: { mode: 'only-on-failure', fullPage: true },
  video: { mode: 'retain-on-failure', size: { width: 1280, height: 720 } },
  trace: { mode: 'on', screenshots: true, snapshots: true, sources: true },
  outputDir: 'test-results',      // change artifact dir (CLI: --output custom-dir)
}
```

### In-test capture

```ts
await page.screenshot({ path: 'shot.png', fullPage: true });   // extras: clip, mask, animations, caret, type (png/jpeg), quality
await page.video().saveAs('demo.webm');                        // page.video() is null unless video is enabled in config
```

### Visual snapshot testing

```ts
await expect(page).toHaveScreenshot();          // compares against stored baseline
```

```bash
playwright test --update-snapshots   # -u: store/refresh baselines
playwright test --ignore-snapshots   # skip snapshot comparisons
```

Baselines live next to the test file (`*.png`). Use for critical, stable UIs only — they degrade on unrelated visual changes.

---

## Configuration

Key `playwright.config.ts` options:

```ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: [['line'], ['html', { open: 'never' }]],
  use: {
    baseURL: 'http://localhost:4000',
    screenshot: process.env.SCREENSHOT || 'off',
    video: process.env.VIDEO || 'off',
    trace: process.env.TRACE || 'off',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    // { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    // { name: 'webkit',  use: { ...devices['Desktop Safari'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:4000',
    reuseExistingServer: !process.env.CI,
  },
});
```

---

## Running Tests

```bash
playwright test                      # run all (parallel, headless, all browsers in config)
playwright test tests/login.spec.ts  # single file
playwright test --grep @smoke        # tag filter
playwright test --headed             # watch it happen
playwright test --debug              # debugger + inspector (also: --ui)
playwright test --project chromium   # one browser only
playwright test --workers 4          # parallelism
playwright test --list               # dry-run listing
playwright test --last-failed        # rerun failures only
playwright test -u / --update-snapshots
playwright test --trace on           # per-run trace
playwright test --output custom-dir  # artifacts location
playwright show-report               # open HTML report
```

---

## Agent Conventions & Checklist

When generating tests, follow these rules:

- [ ] Import `{ test, expect }` from `@playwright/test`.
- [ ] Wait for the app with `page.goto(...)` + web-first assertions; **no arbitrary `setTimeout`/`waitForTimeout`**.
- [ ] Prefer role/label/placeholder/text locators; use `data-testid` for custom components; CSS/XPath last.
- [ ] Assert on locators with `toHaveText`/`toBeVisible` etc. rather than reading values once.
- [ ] Never share auth/state between tests — create fresh users (or use `storageState` only by deliberate convention, defined in config via `setup` projects).
- [ ] Keep each test focused on one flow; use `test.describe` for grouping and `beforeEach` for repeated setup.
- [ ] Clean up side effects (`test.afterEach`), e.g. deleting created records via API.
- [ ] Tag smoke-critical flows with `@smoke` (`test('... @smoke', ...)` or `test.describe(..., { tag: '@smoke' })`).
- [ ] Use `testInfo.attach()` / `console` logging only when it aids debugging; screenshots/video/trace are the primary failure artifacts.
- [ ] Verify the test passes locally (headless) and after `--update-snapshots` where applicable, and that it is not dependent on other tests or on ordering.

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| `strict mode violation` | Locator matches multiple elements — add filters (`filter({ hasText })`), `.first()`, or a more specific role/name |
| `Timeout 30s exceeded` on goto | Server not up — check `webServer` config; or the URL redirects unexpectedly (assert final URL) |
| `Test timeout exceeded` on action | Element not actionable/hidden under overlay — wait for the blocker to disappear, or use `toBeEnabled` first |
| Element found but not visible | Matching a hidden/collapsed element — assert `toBeVisible()`, filter by visible state, or fix the selector |
| Test works headed, fails headless | Timing: replace sleeps with explicit `waitFor({ state })`; viewport-dependent: set `use: { viewport }` |
| Flaky in parallel | Shared state/global mutation (e.g., localStorage, singletons) — isolate per test |
| Snapshot mismatch | Intentional UI change → `-u` to update; flaky assets (dates, ids) → mask with `mask: []` or assert structure instead |
| Browser download errors | Run `npx playwright install` after updating `@playwright/test` |

---

Docs: https://playwright.dev/docs/intro · CLI reference: https://playwright.dev/docs/test-cli