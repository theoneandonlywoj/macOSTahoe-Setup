#!/bin/zsh
# === install_1password.zsh ===
# Purpose: Install 1Password on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj (style inspired)

echo "🚀 Starting 1Password installation on macOS Tahoe..."
echo

# === Configuration ===
brew_path="/opt/homebrew/bin/brew"
app_path="/Applications/1Password.app"

echo "📦 Target application: $app_path"
echo

# === 1. Check and install Homebrew if missing ===
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

# === 2. Install 1Password ===
echo
echo "📥 Installing 1Password..."
if brew list 1password &>/dev/null; then
  echo "✅ 1Password is already installed."
else
  brew install --cask 1password
fi

# === 3. Verify installation ===
if [[ -d "$app_path" ]]; then
  echo "✅ 1Password installed successfully: $app_path"
else
  echo "❌ 1Password installation failed. Aborting."
  exit 1
fi

# === 4. Post-installation info ===
echo
echo "🧪 Verifying..."
if open -Ra "1Password"; then
  echo "✅ 1Password is ready to launch!"
else
  echo "⚠️  Unable to verify app launch. Check installation manually."
fi

# === 5. Wrap-up ===
echo
echo "🎉 1Password installation complete!"
echo
echo "💡 Next steps:"
echo "   • Launch 1Password via Spotlight (⌘ + Space → '1Password')"
echo "   • Sign in with your 1Password account"
echo "   • Configure browser extensions or Touch ID if desired"
echo "   • Run dock_cleanup.zsh to add 1Password to your Dock"
echo
echo "🔐 You're now ready for secure password management."