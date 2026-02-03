#!/bin/zsh
# === OpenClaw macOS Setup Script ===
# Author: theoneandonlywoj
# Description:
#   Installs Xcode Command Line Tools, verifies Git,
#   installs Homebrew package manager, Tailscale VPN, Jira CLI, Okta Verify,
#   Claude Code, GitHub CLI, and OpenClaw. Skips steps that are already completed.

echo "🦞 OpenClaw macOS Setup Script"
echo "----------------------------------------------------"
echo

# === 1. Pre-flight Check ===
echo "🔍 Checking current setup status..."

xcode_installed=false
git_installed=false
brew_installed=false
tailscale_installed=false
jira_installed=false
okta_installed=false
claude_installed=false
gh_installed=false
openclaw_installed=false

if xcode-select -p >/dev/null 2>&1; then
  xcode_installed=true
  echo "✅ Xcode Command Line Tools: Installed"
else
  echo "❌ Xcode Command Line Tools: Not installed"
fi

if command -v git >/dev/null 2>&1; then
  git_installed=true
  echo "✅ Git: Installed ($(git --version))"
else
  echo "❌ Git: Not installed"
fi

if command -v brew >/dev/null 2>&1; then
  brew_installed=true
  echo "✅ Homebrew: Installed ($(brew --version | head -n1))"
else
  echo "❌ Homebrew: Not installed"
fi

if [[ -d "/Applications/Tailscale.app" ]]; then
  tailscale_installed=true
  echo "✅ Tailscale: Installed"
else
  echo "❌ Tailscale: Not installed"
fi

if command -v jira >/dev/null 2>&1; then
  jira_installed=true
  echo "✅ Jira CLI: Installed"
else
  echo "❌ Jira CLI: Not installed"
fi

if [[ -d "/Applications/Okta Verify.app" ]]; then
  okta_installed=true
  echo "✅ Okta Verify: Installed"
else
  echo "❌ Okta Verify: Not installed"
fi

if [[ -d "/Applications/Claude.app" ]]; then
  claude_installed=true
  echo "✅ Claude Code: Installed"
else
  echo "❌ Claude Code: Not installed"
fi

if command -v gh >/dev/null 2>&1; then
  gh_installed=true
  echo "✅ GitHub CLI: Installed"
else
  echo "❌ GitHub CLI: Not installed"
fi

if command -v openclaw >/dev/null 2>&1; then
  openclaw_installed=true
  echo "✅ OpenClaw: Installed"
else
  echo "❌ OpenClaw: Not installed"
fi

echo

# Check if everything is already set up
if [[ "$xcode_installed" == "true" && "$git_installed" == "true" && "$brew_installed" == "true" && "$tailscale_installed" == "true" && "$jira_installed" == "true" && "$okta_installed" == "true" && "$claude_installed" == "true" && "$gh_installed" == "true" && "$openclaw_installed" == "true" ]]; then
  echo "🎉 Everything is already set up!"
  echo "➡️  Nothing to do. Your system is ready."
  echo "----------------------------------------------------"
  exit 0
fi

# === 2. Install Xcode Command Line Tools ===
echo "🔧 Step 1: Xcode Command Line Tools"
echo

if [[ "$xcode_installed" == "true" ]]; then
  echo "ℹ️  Xcode Command Line Tools already installed. Skipping..."
else
  echo "📥 Installing Xcode Command Line Tools..."
  echo "⚠️  A dialog will appear. Please click 'Install' and wait for completion."
  echo
  
  xcode-select --install 2>/dev/null
  
  # Wait for installation to complete
  echo "⏳ Waiting for Xcode Command Line Tools installation to complete..."
  echo "   (This may take several minutes)"
  echo
  
  # Poll until xcode-select -p succeeds
  while ! xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
  
  if xcode-select -p >/dev/null 2>&1; then
    echo "✅ Xcode Command Line Tools installed successfully!"
  else
    echo "❌ Xcode Command Line Tools installation failed."
    echo "⚠️  Please try running 'xcode-select --install' manually."
    exit 1
  fi
fi

echo

# === 3. Verify Git Installation ===
echo "🔧 Step 2: Git Verification"
echo

if command -v git >/dev/null 2>&1; then
  git_version=$(git --version)
  echo "✅ Git is available!"
  echo "   $git_version"
else
  echo "❌ Git is not available."
  echo "⚠️  Git should be bundled with Xcode Command Line Tools."
  echo "   Please verify Xcode CLI tools are properly installed."
  exit 1
fi

echo

# === 4. Install Homebrew ===
echo "🔧 Step 3: Homebrew Installation"
echo

if [[ "$brew_installed" == "true" ]]; then
  echo "ℹ️  Homebrew already installed. Skipping..."
else
  # Detect CPU architecture (Intel vs Apple Silicon)
  echo "🧠 Detecting system architecture..."
  arch_name=$(uname -m)
  if [[ "$arch_name" == "arm64" ]]; then
    echo "🍏 Detected Apple Silicon (M1/M2/M3/M4)..."
    brew_path="/opt/homebrew/bin/brew"
    brew_shell_line='eval "$(/opt/homebrew/bin/brew shellenv)"'
  else
    echo "💻 Detected Intel-based Mac..."
    brew_path="/usr/local/bin/brew"
    brew_shell_line='eval "$(/usr/local/bin/brew shellenv)"'
  fi
  echo

  # Install Homebrew
  echo "📥 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ $? -ne 0 ]]; then
    echo "❌ Homebrew installation failed!"
    echo "⚠️  Please check your internet connection or permissions."
    exit 1
  fi

  echo
  echo "✅ Homebrew installation completed successfully."

  # Configure PATH for Zsh
  echo "🔧 Adding Homebrew to PATH..."

  # Append brew init line if not already in .zprofile
  if ! grep -q "$brew_shell_line" ~/.zprofile 2>/dev/null; then
    echo "$brew_shell_line" >> ~/.zprofile
    echo "📄 Updated ~/.zprofile with Homebrew path"
  else
    echo "ℹ️  Homebrew path already configured in ~/.zprofile"
  fi

  # Apply immediately to current shell session
  eval "$brew_shell_line"

  # Verify installation
  echo
  echo "🧪 Verifying Homebrew installation..."
  if command -v brew >/dev/null 2>&1; then
    brew_version=$(brew --version | head -n1)
    echo "✅ Homebrew is ready to use!"
    echo "   $brew_version"
  else
    echo "❌ Homebrew not found in PATH."
    echo "⚙️  Try restarting your terminal or running:"
    echo "   $brew_shell_line"
    exit 1
  fi
fi

echo

# === 5. Install Tailscale ===
echo "🔧 Step 4: Tailscale Installation"
echo

if [[ "$tailscale_installed" == "true" ]]; then
  echo "ℹ️  Tailscale already installed. Skipping..."
else
  echo "📥 Installing Tailscale..."
  brew install --cask tailscale

  if [[ $? -ne 0 ]]; then
    echo "❌ Tailscale installation failed!"
    echo "⚠️  Please try running 'brew install --cask tailscale' manually."
    exit 1
  fi

  echo "✅ Tailscale installed successfully!"
  echo
  echo "💡 To start Tailscale:"
  echo "   • Open Tailscale from Applications"
  echo "   • Or run: open /Applications/Tailscale.app"
fi

echo

# === 6. Install Jira CLI ===
echo "🔧 Step 5: Jira CLI Installation"
echo

if [[ "$jira_installed" == "true" ]]; then
  echo "ℹ️  Jira CLI already installed. Skipping..."
else
  echo "📥 Installing Jira CLI..."
  brew install jira-cli

  if [[ $? -ne 0 ]]; then
    echo "❌ Jira CLI installation failed!"
    echo "⚠️  Please try running 'brew install jira-cli' manually."
    exit 1
  fi

  echo "✅ Jira CLI installed successfully!"
  echo
  echo "💡 To configure Jira CLI:"
  echo "   • Run: jira init"
  echo "   • Follow the prompts to connect to your Jira instance"
fi

echo

# === 7. Install Okta Verify ===
echo "🔧 Step 6: Okta Verify Installation"
echo

if [[ "$okta_installed" == "true" ]]; then
  echo "ℹ️  Okta Verify already installed. Skipping..."
else
  echo "📥 Installing Okta Verify..."
  brew install --cask okta-verify

  if [[ $? -ne 0 ]]; then
    echo "❌ Okta Verify installation failed!"
    echo "⚠️  Please try running 'brew install --cask okta-verify' manually."
    exit 1
  fi

  echo "✅ Okta Verify installed successfully!"
  echo
  echo "💡 To set up Okta Verify:"
  echo "   • Open Okta Verify from Applications"
  echo "   • Follow the prompts to add your organization"
fi

echo

# === 8. Install Claude Code ===
echo "🔧 Step 7: Claude Code Installation"
echo

if [[ "$claude_installed" == "true" ]]; then
  echo "ℹ️  Claude Code already installed. Skipping..."
else
  echo "📥 Installing Claude Code..."
  brew install --cask claude-code

  if [[ $? -ne 0 ]]; then
    echo "❌ Claude Code installation failed!"
    echo "⚠️  Please try running 'brew install --cask claude-code' manually."
    exit 1
  fi

  echo "✅ Claude Code installed successfully!"
  echo
  echo "💡 To use Claude Code:"
  echo "   • Open Claude from Applications"
  echo "   • Or run: open /Applications/Claude.app"
fi

echo

# === 9. Install GitHub CLI ===
echo "🔧 Step 8: GitHub CLI Installation"
echo

if [[ "$gh_installed" == "true" ]]; then
  echo "ℹ️  GitHub CLI already installed. Skipping..."
else
  echo "📥 Installing GitHub CLI..."
  brew install gh

  if [[ $? -ne 0 ]]; then
    echo "❌ GitHub CLI installation failed!"
    echo "⚠️  Please try running 'brew install gh' manually."
    exit 1
  fi

  echo "✅ GitHub CLI installed successfully!"
  echo
  echo "💡 To configure GitHub CLI:"
  echo "   • Run: gh auth login"
  echo "   • Follow the prompts to authenticate with GitHub"
fi

echo

# === 10. Install OpenClaw ===
echo "🔧 Step 9: OpenClaw Installation"
echo

if [[ "$openclaw_installed" == "true" ]]; then
  echo "ℹ️  OpenClaw already installed. Skipping..."
else
  echo "📥 Installing OpenClaw..."
  curl -fsSL https://openclaw.ai/install.sh | bash

  if [[ $? -ne 0 ]]; then
    echo "❌ OpenClaw installation failed!"
    echo "⚠️  Please try running 'curl -fsSL https://openclaw.ai/install.sh | bash' manually."
    exit 1
  fi

  echo "✅ OpenClaw installed successfully!"
  echo
  echo "💡 To use OpenClaw:"
  echo "   • Run: openclaw"
  echo "   • Or run: openclaw --help for available commands"
fi

echo

# === 11. Summary ===
echo "----------------------------------------------------"
echo "🎉 OpenClaw Setup Complete!"
echo
echo "📋 Installed Components:"
echo "   • Xcode Command Line Tools: $(xcode-select -p 2>/dev/null || echo 'N/A')"
echo "   • Git: $(git --version 2>/dev/null || echo 'N/A')"
echo "   • Homebrew: $(brew --version 2>/dev/null | head -n1 || echo 'N/A')"
echo "   • Tailscale: $([[ -d '/Applications/Tailscale.app' ]] && echo 'Installed' || echo 'N/A')"
echo "   • Jira CLI: $(command -v jira >/dev/null 2>&1 && echo 'Installed' || echo 'N/A')"
echo "   • Okta Verify: $([[ -d '/Applications/Okta Verify.app' ]] && echo 'Installed' || echo 'N/A')"
echo "   • Claude Code: $([[ -d '/Applications/Claude.app' ]] && echo 'Installed' || echo 'N/A')"
echo "   • GitHub CLI: $(command -v gh >/dev/null 2>&1 && echo 'Installed' || echo 'N/A')"
echo "   • OpenClaw: $(command -v openclaw >/dev/null 2>&1 && echo 'Installed' || echo 'N/A')"
echo
echo "💡 Next steps:"
echo "   • Run 'brew doctor' to verify Homebrew setup"
echo "   • Open Tailscale and sign in to your account"
echo "   • Run 'jira init' to configure Jira CLI"
echo "   • Open Okta Verify and add your organization (or add it from your Mac with Open Okta Verify -> Add Account to another device)"
echo "   • Open Claude from Applications to start using it"
echo "   • Run 'gh auth login' to authenticate GitHub CLI"
echo "   • Run 'openclaw' to start using OpenClaw"
echo "   • Configure Git with your name and email" (optional)
echo "   • Set up SSH keys for GitHub" (optional)
echo
echo "✨ Your Mac is ready for OpenClaw bot!"
echo "----------------------------------------------------"
