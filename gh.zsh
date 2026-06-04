#!/bin/zsh
# === install_github_cli.zsh ===
# Purpose: Install GitHub CLI (gh) on macOS Tahoe with Zsh
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "🚀 Starting GitHub CLI (gh) installation on macOS Tahoe..."
echo

# === Configuration ===
brew_path="/opt/homebrew/bin/brew"
gh_bin="/opt/homebrew/bin/gh"

echo "📦 Target binary: $gh_bin"
echo "🧠 Shell: Zsh"
echo

# === 1. Ensure Homebrew is available ===
if ! command -v brew >/dev/null 2>&1; then
  echo "⚙️  Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "💡 Adding Homebrew to PATH..."
  if [[ -d "/opt/homebrew/bin" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo "✅ Homebrew installed successfully."
else
  echo "✅ Homebrew already installed."
fi

# === 2. Install GitHub CLI ===
echo
echo "📥 Installing GitHub CLI (gh)..."
if brew list gh &>/dev/null; then
  echo "ℹ️  GitHub CLI is already installed. Upgrading to latest version..."
  brew upgrade gh || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install gh
fi

# === 3. Verify installation ===
if command -v gh >/dev/null 2>&1; then
  echo "✅ GitHub CLI installed successfully!"
else
  echo "❌ Installation failed. Aborting."
  exit 1
fi

# === 4. Add to PATH (if necessary) ===
if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
  echo "🧩 Adding Homebrew to PATH in ~/.zshrc..."
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
  source ~/.zshrc
  echo "✅ PATH updated for Homebrew binaries."
fi

# === 5. Verify gh version ===
echo
echo "🧪 Verifying gh version..."
gh_version=$(gh --version | head -n 1)
echo "📘 $gh_version"
echo

# === 6. GitHub authentication guidance ===
if ! gh auth status >/dev/null 2>&1; then
  echo "🔐 You’re not logged in to GitHub CLI."
  echo "👉 Run the following command to authenticate:"
  echo
  echo "   gh auth login"
  echo
  echo "💡 Choose:"
  echo "   • GitHub.com (default)"
  echo "   • HTTPS (recommended)"
  echo "   • Open browser for authentication"
else
  echo "✅ GitHub CLI is already authenticated."
fi

# === 7. Wrap-up ===
echo
echo "🎉 GitHub CLI setup complete!"
echo
echo "💡 Next steps:"
echo "   • Verify login: gh auth status"
echo "   • Create a new repo: gh repo create"
echo "   • Clone an existing repo: gh repo clone <user>/<repo>"
echo "   • Check pull requests: gh pr list"
echo
echo "🐙 Happy coding with GitHub CLI!"
