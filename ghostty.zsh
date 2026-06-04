#!/bin/zsh
# === ghostty.zsh ===
# Purpose: Install Ghostty terminal emulator on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "👻 Starting installation of Ghostty terminal emulator on macOS Tahoe..."
echo

# === Configuration ===
ghostty_app="/Applications/Ghostty.app"

echo "📂 Target path:        $ghostty_app"
echo

# === 1. Check if Ghostty is already installed ===
if [[ -d "$ghostty_app" ]]; then
  current_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$ghostty_app/Contents/Info.plist" 2>/dev/null || echo "unknown")
  echo "✅ Ghostty is already installed at $ghostty_app (version: $current_version)"
  echo
  echo "💡 To update, run: brew upgrade --cask ghostty"
  echo "🎉 Nothing to do!"
  exit 0
fi

# === 2. Ensure Homebrew is installed ===
if ! command -v brew >/dev/null 2>&1; then
  echo "⚙️  Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -d "/opt/homebrew/bin" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo "✅ Homebrew installed."
  echo
fi

# === 3. Install Ghostty via Homebrew cask ===
echo "📥 Installing Ghostty via Homebrew cask..."
brew install --cask ghostty
if [[ $? -ne 0 ]]; then
  echo "❌ Homebrew cask install failed."
  echo "⚠️  Try running manually: brew install --cask ghostty"
  exit 1
fi
echo "✅ Ghostty installed via Homebrew"
echo

# === 4. Verify installation ===
echo "🧪 Verifying installation..."
echo

if [[ -d "$ghostty_app" ]]; then
  installed_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$ghostty_app/Contents/Info.plist" 2>/dev/null || echo "unknown")
  echo "✅ Ghostty: installed at $ghostty_app (version: $installed_version)"
else
  echo "⚠️  Ghostty not found at $ghostty_app"
  echo "   It may have installed elsewhere. Check with: mdfind 'kMDItemCFBundleIdentifier == com.mitchellh.ghostty'"
  exit 1
fi

echo
echo "🎉 Ghostty installation complete!"
echo
echo "💡 Next steps:"
echo "   • Launch Ghostty via Spotlight (⌘ Space → 'Ghostty')"
echo "   • Config file: ~/.config/ghostty/config"
echo "   • Docs: https://ghostty.org/docs"
echo "   • Run dock_cleanup.zsh to add Ghostty to your Dock"