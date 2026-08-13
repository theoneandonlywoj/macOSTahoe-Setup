#!/bin/zsh
# === playwright.zsh ===
# Purpose: Install Playwright CLI (browser automation & testing, Node.js) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)
# Docs: https://playwright.dev/docs/intro

echo "🎭  Starting Playwright CLI installation on macOS Tahoe..."
echo

# === Configuration ===
playwright_bin="playwright"

echo "🔗 Binary:             $playwright_bin"
echo

# === 1. Check if Playwright is already installed ===
if command -v "$playwright_bin" >/dev/null 2>&1; then
  current_version=$("$playwright_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Playwright is already installed: $playwright_bin (version: $current_version)"
  echo
  echo "💡 To update, run: npm install -g playwright"
  echo "   To update browsers: playwright install"
  echo "🎉 Nothing to do!"
  exit 0
fi

# === 2. Check and install Node.js 18+ and npm (required) ===
echo "📋 Checking prerequisites: Node.js 18+ and npm..."
echo

node_ok=false
if command -v node >/dev/null 2>&1; then
  node_version=$(node --version 2>/dev/null | tr -d 'v')
  if node -e 'const [m,n]=process.versions.node.split(".").map(Number); process.exit(m>18||(m===18)?0:1)' >/dev/null 2>&1; then
    echo "✅ Node.js found: v$node_version (18+ required)"
    node_ok=true
  else
    echo "⚠️  Node.js found but too old: v$node_version (18+ required)"
  fi
else
  echo "⚙️  Node.js not found."
fi

if command -v npm >/dev/null 2>&1; then
  echo "✅ npm found: $(npm --version 2>/dev/null)"
else
  echo "⚠️  npm not found."
fi

if [[ "$node_ok" = false ]]; then
  echo
  echo "⚙️  Installing Node.js via Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    echo "⚙️  Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "💡 Adding Homebrew to PATH..."
    if [[ -d "/opt/homebrew/bin" ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo "✅ Homebrew installed."
  else
    echo "✅ Homebrew already installed."
  fi

  if brew list node &>/dev/null; then
    brew upgrade node
  else
    brew install node
  fi

  if ! command -v node >/dev/null 2>&1 || ! node -e 'const [m,n]=process.versions.node.split(".").map(Number); process.exit(m>18||(m===18)?0:1)' >/dev/null 2>&1; then
    echo "❌ Node.js 18+ is required. Please install it and rerun this script."
    exit 1
  fi
  echo "✅ Node.js installed: $(node --version)"
fi
echo

# === 3. Install Playwright CLI ===
echo "📥 Installing Playwright via npm (global install)..."
npm install -g playwright
install_status=$?

if [[ $install_status -ne 0 ]] && ! command -v "$playwright_bin" >/dev/null 2>&1; then
  echo "❌ Playwright install failed (npm install -g)."
  echo "⚠️  Try running manually: npm install -g playwright"
  exit 1
fi

# === 4. Ensure npm global bin is on PATH ===
if command -v "$playwright_bin" >/dev/null 2>&1; then
  echo "✅ Playwright installed successfully."
else
  npm_global_bin=$(npm bin -g 2>/dev/null || npm prefix -g 2>/dev/null)
  if [[ -n "$npm_global_bin" ]] && [[ -x "$npm_global_bin/$playwright_bin" ]]; then
    echo "⚙️  Adding npm global bin to PATH for this session: $npm_global_bin"
    export PATH="$npm_global_bin:$PATH"
    if ! grep -q "$npm_global_bin" ~/.zshrc 2>/dev/null; then
      echo "💡 Adding npm global bin to ~/.zshrc..."
      echo '' >> ~/.zshrc
      echo "# Playwright (npm global bin)" >> ~/.zshrc
      echo "export PATH=\"$npm_global_bin:\$PATH\"" >> ~/.zshrc
    fi
    echo "✅ Playwright installed successfully."
  else
    echo "⚠️  Playwright not found in PATH. You may need to restart your terminal."
  fi
fi
echo

# === 5. Verify installation ===
echo "🧪 Verifying installation..."
echo

if command -v "$playwright_bin" >/dev/null 2>&1; then
  installed_version=$("$playwright_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Playwright: $playwright_bin (version: $installed_version)"
else
  echo "⚠️  Playwright not found in PATH. Open a new terminal and run: $playwright_bin --version"
  exit 1
fi

echo
echo "🎉 Playwright installation complete!"
echo
echo "💡 Next steps:"
echo "   • Install browsers (Chromium, Firefox, WebKit):  playwright install"
echo "   • Bootstrap a project:                           npm init playwright@latest"
echo "   • Add test runner to a project:                  npm i -D @playwright/test"
echo "   • Record a test interactively:                   playwright codegen https://example.com"
echo "   • Run all tests:                                 playwright test"
echo "   • Run with screenshots:                          SCREENSHOT=on playwright test"
echo "   • Run recording video:                           VIDEO=retain-on-failure playwright test"
echo "   • Open last report:                              playwright show-report"
echo "   • Check all options:                             playwright --help"
echo

# === 6. CLI use-cases ===
echo "🛠️  CLI use-cases:"
echo "   # Install all browsers (first run, large download)"
echo "   playwright install"
echo "   # Install a single browser (e.g. Chromium only)"
echo "   playwright install chromium"
echo "   # Generate a test by driving a browser manually"
echo "   playwright codegen localhost:4000"
echo "   # Run the test suite (uses playwright.config.ts)"
echo "   playwright test"
echo "   # Run a single test file"
echo "   playwright test tests/login.spec.ts"
echo "   # Run headed (watch it happen) with a tagged test"
echo "   playwright test --headed --grep @smoke"
echo "   # Debug with inspector / open the HTML report"
echo "   playwright test --debug"
echo "   playwright show-report"
echo

# === 6.5 Screenshots & video recording ===
echo "📸 Screenshots & video recording:"
echo "   # SCREENSHOT options:"
echo "   #   off               -> no screenshots (default)"
echo "   #   on                -> screenshot at every step of every test"
echo "   #   only-on-failure   -> screenshot only when a test fails (saved on failure)"
echo "   SCREENSHOT=only-on-failure playwright test"
echo "   # VIDEO options:"
echo "   #   off                  -> no video recording (default)"
echo "   #   on                   -> record video of every test, keep all"
echo "   #   retain-on-failure    -> record but only keep videos of failed tests"
echo "   #   on-first-retry       -> record only on the first retry of a failed test"
echo "   VIDEO=retain-on-failure playwright test"
echo "   # TRACE options: captures DOM snapshots, network calls, console logs and actions"
echo "   #   off                  -> no trace (default)"
echo "   #   on                   -> trace every test, keep all"
echo "   #   retain-on-failure    -> trace every test but only keep traces of failures"
echo "   #   on-first-retry       -> trace only on the first retry of a failed test"
echo "   playwright test --trace on"
echo "   # Combined: screenshots + video on failure, trace on retry"
echo "   SCREENSHOT=only-on-failure VIDEO=retain-on-failure TRACE=on-first-retry playwright test"
echo "   # Artifacts land in test-results/<test-name>/ (screenshot.png, video.webm, trace.zip)"
echo
echo "   # Make playwright.config.ts honor the env vars above:"
echo '      import { defineConfig } from "@playwright/test";'
echo "      export default defineConfig({"
echo "        use: {"
echo '          screenshot: process.env.SCREENSHOT || "off",'
echo '          video: process.env.VIDEO || "off",'
echo '          trace: process.env.TRACE || "off",'
echo "        },"
echo "      });"
echo
echo "   # In-test capture (video() is null unless video is enabled in config):"
echo "   await page.screenshot({ path: 'shot.png', fullPage: true })"
echo "   await page.video().saveAs('demo.webm')"
echo
echo "   # Extended options (config object forms also accept mode + extras):"
echo "   #   screenshot: { mode: 'only-on-failure', fullPage: true }   (bool mode + fullPage)"
echo "   #   video:      { mode: 'retain-on-failure', size: { width: 1280, height: 720 } }"
echo "   #   trace:      { mode: 'on', screenshots: true, snapshots: true, sources: true }"
echo "   #   outputDir:  'test-results'   (change artifact dir; CLI: playwright test --output custom-dir)"
echo "   # page.screenshot() extras: clip, mask, animations, caret, type (png/jpeg), quality"
echo
echo "   # Visual snapshot testing (compare screenshots against stored baselines):"
echo "   await expect(page).toHaveScreenshot()"
echo "   playwright test --update-snapshots   # -u: refresh/store baselines"
echo "   playwright test --ignore-snapshots   # skip snapshot comparisons"
echo

# === 7. Notes & configuration ===
echo "📂 Configuration:"
echo "   • Project config: playwright.config.ts (testDir, baseURL, projects/browsers, reporters)"
echo "   • Artifacts: test-results/ (screenshots, videos, traces per test); wipe: rm -rf test-results"
echo "   • Browsers cache to ~/Library/Caches/ms-playwright (downloads via 'playwright install')"
echo "   • Node.js managed via Homebrew: brew list node / brew upgrade node"
echo "   • Install globally: npm install -g playwright (this script) — for CLI + browsers"
echo "   • Per-project: npm init playwright@latest  (adds @playwright/test to package.json)"
echo "   • Tests live in tests/ by default; fixtures/ for data; update config after scaffold"
echo "   • Updates: npm install -g playwright && playwright install"
echo "   • Docs: https://playwright.dev/docs/intro"
echo "   • Agent guide (writing tests): docs/guide_playwright_tests.md"
echo "   • CLI reference: https://playwright.dev/docs/test-cli"
echo
echo "▶️  Run: playwright install && playwright codegen https://example.com"