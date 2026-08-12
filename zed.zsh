#!/bin/zsh
# === zed.zsh ===
# Purpose: Install Zed editor on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "🖋️  Starting installation of Zed editor on macOS Tahoe..."
echo

# === Configuration ===
zed_app="/Applications/Zed.app"
zed_bin="/usr/local/bin/zed"

echo "📂 Target path:        $zed_app"
echo

# === 1. Check if Zed is already installed ===
if [[ -d "$zed_app" ]]; then
  current_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$zed_app/Contents/Info.plist" 2>/dev/null || echo "unknown")
  echo "✅ Zed is already installed at $zed_app (version: $current_version)"
  echo
  echo "💡 To update, run: brew upgrade --cask zed"
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

# === 3. Install Zed via Homebrew cask ===
echo "📥 Installing Zed via Homebrew cask (this also sets up the CLI)..."
brew install --cask zed
if [[ $? -ne 0 ]]; then
  echo "❌ Homebrew cask install failed."
  echo "⚠️  Try running manually: brew install --cask zed"
  exit 1
fi
echo "✅ Zed installed via Homebrew"
echo

# === 4. Verify installation ===
echo "🧪 Verifying installation..."
echo

if [[ -d "$zed_app" ]]; then
  installed_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$zed_app/Contents/Info.plist" 2>/dev/null || echo "unknown")
  echo "✅ Zed: installed at $zed_app (version: $installed_version)"
else
  echo "⚠️  Zed not found at $zed_app"
  echo "   It may have installed elsewhere. Check with: mdfind 'kMDItemCFBundleIdentifier == dev.zed.Zed'"
  exit 1
fi

if ! command -v zed >/dev/null 2>&1; then
  echo "⚠️  CLI 'zed' not found on PATH. Reopen your terminal or run: eval \"$(/opt/homebrew/bin/brew shellenv)\""
fi

echo
echo "🎉 Zed installation complete!"
echo
echo "💡 Next steps:"
echo "   • Launch Zed via Spotlight (⌘ Space → 'Zed')"
echo "   • Open the CLI: zed ."
echo "   • Settings: ~/.config/zed/settings.json"
echo "   • Docs: https://zed.dev/docs"
echo "   • Run dock_cleanup.zsh to add Zed to your Dock"