#!/bin/zsh
# === OpenClaw macOS Setup Script ===
# Author: theoneandonlywoj
# Description:
#   Installs Xcode Command Line Tools, verifies Git,
#   installs Homebrew package manager, Tailscale VPN, and Jira CLI.
#   Skips steps that are already completed.

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

echo

# Check if everything is already set up
if [[ "$xcode_installed" == "true" && "$git_installed" == "true" && "$brew_installed" == "true" && "$tailscale_installed" == "true" && "$jira_installed" == "true" ]]; then
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

# === 7. Summary ===
echo "----------------------------------------------------"
echo "🎉 OpenClaw Setup Complete!"
echo
echo "📋 Installed Components:"
echo "   • Xcode Command Line Tools: $(xcode-select -p 2>/dev/null || echo 'N/A')"
echo "   • Git: $(git --version 2>/dev/null || echo 'N/A')"
echo "   • Homebrew: $(brew --version 2>/dev/null | head -n1 || echo 'N/A')"
echo "   • Tailscale: $([[ -d '/Applications/Tailscale.app' ]] && echo 'Installed' || echo 'N/A')"
echo "   • Jira CLI: $(command -v jira >/dev/null 2>&1 && echo 'Installed' || echo 'N/A')"
echo
echo "💡 Next steps:"
echo "   • Run 'brew doctor' to verify Homebrew setup"
echo "   • Open Tailscale and sign in to your account"
echo "   • Run 'jira init' to configure Jira CLI"
echo "   • Configure Git with your name and email" (optional)
echo "   • Set up SSH keys for GitHub" (optional)
echo
echo "✨ Your Mac is ready for OpenClaw bot!"
echo "----------------------------------------------------"
