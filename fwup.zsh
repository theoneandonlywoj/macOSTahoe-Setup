#!/bin/zsh
# === fwup.zsh ===
# Purpose: Install fwup (Nerves firmware updater) on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🔥 Starting fwup installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install fwup ===
echo
echo "📥 Installing fwup via Homebrew..."
if command -v fwup >/dev/null 2>&1; then
  echo "ℹ️  fwup is already installed. Upgrading to latest..."
  brew upgrade fwup 2>/dev/null || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install fwup
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install fwup"
    exit 1
  fi
fi
echo "✅ fwup installed."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

fwup_path=$(which fwup 2>/dev/null)
if [[ -z "$fwup_path" ]]; then
  echo "❌ fwup not found in PATH."
  exit 1
fi
echo "📌 fwup: $fwup_path"

fwup_version=$(fwup --version 2>/dev/null)
if [[ -n "$fwup_version" ]]; then
  echo "📌 Version: $fwup_version"
fi

# === 4. Wrap-up ===
echo
echo "✅ fwup installed successfully!"
echo
echo "💡 Usage (Nerves/Buildroot firmware):"
echo "   • Burn firmware to SD card:    fwup firmware.fw -d -t complete /dev/rdiskN"
echo "   • List tasks in a .fw file:    fwup -l firmware.fw"
echo "   • Apply one task:              fwup firmware.fw -t complete -d /dev/rdiskN"
echo "   • Burn to a raw image:         fwup firmware.fw -d -t complete output.img"
echo "   • Inspect contents:            fwup -i firmware.fw -t complete"
echo
echo "💡 Find your SD card with:  diskutil list   (use /dev/rdiskN, unmount first)"
echo
echo "🎉 Installation finished successfully!"
