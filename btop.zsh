#!/bin/zsh
# === btop.zsh ===
# Purpose: Install btop for system monitoring on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting btop installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install btop ===
echo
echo "📥 Installing btop via Homebrew..."
if command -v btop >/dev/null 2>&1; then
  echo "✅ btop is already installed."
else
  brew install btop
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install btop"
    exit 1
  fi
  echo "✅ btop installed."
fi

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

btop_path=$(which btop 2>/dev/null)
if [[ -z "$btop_path" ]]; then
  echo "❌ btop not found in PATH."
  exit 1
fi
echo "📌 btop: $btop_path"

echo
echo "✅ btop installed successfully!"

# === 4. Wrap-up ===
echo
echo "💡 Usage:"
echo "   • Interactive system monitor:  btop"
echo
echo "🎉 Installation finished successfully!"