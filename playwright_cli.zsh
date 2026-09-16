#!/bin/zsh
# === playwright_cli.zsh ===
# Purpose: Install Playwright CLIs for interactive recording and coding-agent browser automation on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)
# Docs: https://playwright.dev/agent-cli/installation

echo "🎭  Starting Playwright CLI installation on macOS Tahoe..."
echo

# === Configuration ===
typeset -A cli_packages
cli_packages=(
  playwright "playwright"
  playwright-cli "@playwright/cli@latest"
)
required_node_major=20

echo "🔗 Interactive recorder CLI: playwright"
echo "🤖 Coding-agent CLI:         playwright-cli"
echo

verify_cli() {
  local cli="$1"
  local version

  if ! command -v "$cli" >/dev/null 2>&1; then
    return 1
  fi

  if ! version=$("$cli" --version 2>/dev/null) || [[ -z "$version" ]]; then
    echo "⚠️  $cli is on PATH, but its version check failed."
    return 1
  fi

  echo "✅ $cli: $version"
  return 0
}

add_npm_global_bin_to_path() {
  local npm_prefix npm_global_bin

  npm_prefix=$(npm prefix -g 2>/dev/null) || return 1
  npm_global_bin="$npm_prefix/bin"

  if [[ ! -d "$npm_global_bin" ]]; then
    return 1
  fi

  if [[ ":$PATH:" != *":$npm_global_bin:"* ]]; then
    echo "⚙️  Adding npm global bin to PATH for this session: $npm_global_bin"
    export PATH="$npm_global_bin:$PATH"
  fi

  if ! grep -Fq "export PATH=\"$npm_global_bin:\$PATH\"" ~/.zshrc 2>/dev/null; then
    echo "💡 Adding npm global bin to ~/.zshrc..."
    echo '' >> ~/.zshrc
    echo "# npm global command-line tools" >> ~/.zshrc
    echo "export PATH=\"$npm_global_bin:\$PATH\"" >> ~/.zshrc
  fi
}

# === 1. Check and install Node.js 20+ and npm ===
echo "📋 Checking prerequisites: Node.js ${required_node_major}+ and npm..."
echo

node_ok=false
npm_ok=false

if command -v node >/dev/null 2>&1; then
  node_version=$(node --version 2>/dev/null)
  if node -e "process.exit(Number(process.versions.node.split('.')[0]) >= ${required_node_major} ? 0 : 1)" >/dev/null 2>&1; then
    echo "✅ Node.js found: $node_version (${required_node_major}+ required)"
    node_ok=true
  else
    echo "⚠️  Node.js found but too old: ${node_version:-unknown} (${required_node_major}+ required)"
  fi
else
  echo "⚙️  Node.js not found."
fi

if command -v npm >/dev/null 2>&1; then
  echo "✅ npm found: $(npm --version 2>/dev/null)"
  npm_ok=true
else
  echo "⚠️  npm not found."
fi

if [[ "$node_ok" = false || "$npm_ok" = false ]]; then
  echo
  echo "⚙️  Installing or upgrading Node.js via Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    echo "⚙️  Homebrew not found. Installing..."
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      echo "❌ Homebrew installation failed. Install Homebrew manually, then rerun this script."
      exit 1
    fi

    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    elif [[ -x "/usr/local/bin/brew" ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
      echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
    fi
    echo "✅ Homebrew installed."
  else
    echo "✅ Homebrew already installed."
  fi

  if brew list node &>/dev/null; then
    if ! brew upgrade node; then
      echo "❌ Homebrew could not upgrade Node.js. Try manually: brew upgrade node"
      exit 1
    fi
  else
    if ! brew install node; then
      echo "❌ Homebrew could not install Node.js. Try manually: brew install node"
      exit 1
    fi
  fi

  if ! command -v node >/dev/null 2>&1 || ! node -e "process.exit(Number(process.versions.node.split('.')[0]) >= ${required_node_major} ? 0 : 1)" >/dev/null 2>&1; then
    echo "❌ Node.js ${required_node_major}+ is required. Install it and rerun this script."
    exit 1
  fi
  if ! command -v npm >/dev/null 2>&1; then
    echo "❌ npm is required. Install it with Node.js and rerun this script."
    exit 1
  fi

  echo "✅ Node.js ready: $(node --version)"
  echo "✅ npm ready: $(npm --version)"
fi
echo

# === 2. Check and install each CLI independently ===
typeset -a cli_names
cli_names=(playwright playwright-cli)

for cli in "${cli_names[@]}"; do
  package="${cli_packages[$cli]}"
  echo "🧪 Checking $cli..."

  if verify_cli "$cli"; then
    echo "   No package installation needed."
    echo
    continue
  fi

  echo "📥 Installing $package globally with npm..."
  if ! npm install -g "$package"; then
    echo "❌ Installation failed for $package."
    echo "⚠️  Try running manually: npm install -g $package"
    echo "❌ Playwright CLI setup did not complete."
    exit 1
  fi

  if ! command -v "$cli" >/dev/null 2>&1; then
    add_npm_global_bin_to_path || true
  fi

  if ! verify_cli "$cli"; then
    echo "❌ $package installed, but '$cli --version' did not succeed."
    echo "⚠️  Open a new terminal, then run: $cli --version"
    echo "⚠️  To reinstall manually: npm install -g $package"
    echo "❌ Playwright CLI setup did not complete."
    exit 1
  fi
  echo
done

# === 3. Final verification and usage guidance ===
echo "🧪 Final verification..."
for cli in "${cli_names[@]}"; do
  if ! verify_cli "$cli"; then
    echo "❌ Final verification failed for $cli. Playwright CLI setup did not complete."
    exit 1
  fi
done

echo
echo "🎉 Playwright command-line tooling is ready!"
echo
echo "💡 Next steps:"
echo "   • Explore with a coding agent:    playwright-cli open https://example.com"
echo "   • Use an isolated named session:  playwright-cli -s=example open https://example.com"
echo "   • Close that agent session:       playwright-cli -s=example close"
echo "   • Record a flow interactively:    playwright codegen https://example.com"
echo "   • Install recorder/test browsers: playwright install"
echo "   • Install the agent browser now:  playwright-cli install-browser"
echo
echo "📦 Durable Playwright Test specs use the target project's local dependency and config:"
echo "   • From the target project:        npm i -D @playwright/test"
echo "   • Install its pinned browser:     npx playwright install"
echo "   • Run its local test suite:       npx playwright test"
echo "   • Run one local spec:             npx playwright test tests/example.spec.ts"
echo "   Global 'playwright' and 'playwright-cli' do not replace project-local @playwright/test."
echo
echo "📚 References:"
echo "   • Agent CLI:  https://playwright.dev/agent-cli/introduction"
echo "   • Test CLI:   https://playwright.dev/docs/test-cli"
echo "   • Local guide: docs/guide_playwright_tests.md"
