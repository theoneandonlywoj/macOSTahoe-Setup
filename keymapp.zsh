#!/bin/zsh
# === keymapp.zsh ===
# Purpose: Install or update Keymapp for ZSA keyboards on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "🚀 Starting Keymapp installation/update on macOS Tahoe..."
echo

# === Configuration ===
keymapp_app="/Applications/Keymapp.app"

# === 1. Check if Keymapp is already installed ===
if [[ -d "$keymapp_app" ]]; then
  current_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$keymapp_app/Contents/Info.plist" 2>/dev/null || echo "unknown")
  echo "✅ Keymapp is already installed at $keymapp_app (version: $current_version)"
  echo
  echo "🔄 Updating Keymapp via Homebrew..."
  brew upgrade --cask keymapp
  if [[ $? -ne 0 ]]; then
    echo "ℹ️  Keymapp may already be at the latest version."
  fi

  updated_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$keymapp_app/Contents/Info.plist" 2>/dev/null || echo "unknown")
  echo
  echo "📌 Keymapp version: $updated_version"
  echo "✅ Keymapp update complete!"
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

# === 3. Install Keymapp via Homebrew cask ===
echo "📥 Installing Keymapp via Homebrew cask..."
brew install --cask keymapp
if [[ $? -ne 0 ]]; then
  echo "❌ Homebrew cask install failed."
  echo "⚠️  Try running manually: brew install --cask keymapp"
  exit 1
fi
echo "✅ Keymapp installed via Homebrew"
echo

# === 4. Verify installation ===
echo "🧪 Verifying installation..."
echo

if [[ -d "$keymapp_app" ]]; then
  installed_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$keymapp_app/Contents/Info.plist" 2>/dev/null || echo "unknown")
  echo "✅ Keymapp: installed at $keymapp_app (version: $installed_version)"
else
  echo "⚠️  Keymapp not found at $keymapp_app"
  echo "   It may have installed elsewhere. Check with: mdfind 'kMDItemCFBundleIdentifier == tech.zsa.keymapp'"
  exit 1
fi

# === 5. Wrap-up ===
echo
echo "🎉 Keymapp installation complete!"
echo
echo "💡 Next steps:"
echo "   • Launch Keymapp via Spotlight (⌘ Space → 'Keymapp')"
echo "   • On first launch, macOS may prompt for Accessibility and Input Monitoring permissions"
echo "   • Grant those permissions in System Settings → Privacy & Security for full keyboard support"
echo "   • To update later, re-run this script or run: brew upgrade --cask keymapp"