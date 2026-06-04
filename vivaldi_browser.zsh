#!/bin/zsh
# === vivaldi_browser.zsh ===
# Purpose: Install Vivaldi browser on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "🚀 Starting installation of Vivaldi browser on macOS Tahoe..."
echo

# === Configuration ===
vivaldi_app="/Applications/Vivaldi.app"
echo "📂 Target installation path: $vivaldi_app"
echo

# === 1. Install Vivaldi ===
if command -v brew >/dev/null 2>&1; then
  echo "🍺 Homebrew detected."
  echo "📦 Installing Vivaldi via Homebrew Cask..."
  brew install --cask vivaldi
  if [[ $? -eq 0 ]]; then
    echo "✅ Vivaldi installed successfully via Homebrew!"
  else
    echo "❌ Failed to install Vivaldi via Homebrew."
    exit 1
  fi
else
  echo "❌ Homebrew not found."
  echo
  echo "📋 Please install Homebrew first:"
  echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  echo
  echo "   Then run this script again."
  exit 1
fi

# === 2. Verify installation ===
if [[ ! -d "$vivaldi_app" ]]; then
  echo "❌ Vivaldi installation failed."
  exit 1
fi

echo
echo "🚀 Vivaldi installed at: $vivaldi_app"

# === 3. Verification and wrap-up ===
echo
echo "🧪 Verifying installation..."
echo "✅ Vivaldi installation confirmed at $vivaldi_app"

echo
echo "🎉 Vivaldi browser installation complete!"
echo
echo "💡 Next steps:"
echo "   • Launch Vivaldi via Launchpad or Spotlight (⌘ Space → 'Vivaldi')"
echo "   • Set Vivaldi as your default browser in System Settings if desired"
echo "   • Run dock_cleanup.zsh to add Vivaldi to your Dock"
echo "   • Enjoy your privacy-first browsing experience!"