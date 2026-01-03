#!/bin/zsh
# === kafka_cli.zsh ===
# Purpose: Install a Kafka CLI (`kaf`) on macOS using Homebrew and configure Zsh completion
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting Kafka CLI (kaf) installation on macOS..."
echo

# === 0. Basic sanity checks ===

# macOS check
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ This script is intended for macOS only."
  exit 1
fi

# Check for Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed."
  echo "   Please install Homebrew first from: https://brew.sh"
  exit 1
fi
echo "✅ Homebrew detected."

# === 1. Install kaf (Kafka CLI) via Homebrew ===
echo
echo "📥 Installing Kafka CLI 'kaf' via Homebrew..."

# Ensure tap is present
if ! brew tap | grep -q "^birdayz/kaf\$"; then
  echo "ℹ️  Adding Homebrew tap: birdayz/kaf"
  if ! brew tap birdayz/kaf; then
    echo "❌ Failed to tap birdayz/kaf."
    exit 1
  fi
else
  echo "ℹ️  Homebrew tap 'birdayz/kaf' already present."
fi

if brew list kaf >/dev/null 2>&1; then
  echo "ℹ️  'kaf' is already installed. Upgrading to latest..."
  if ! brew upgrade kaf; then
    echo "⚠️  Failed to upgrade kaf. Continuing with existing version."
  fi
else
  if ! brew install kaf; then
    echo "❌ Failed to install kaf via Homebrew."
    exit 1
  fi
fi

if ! command -v kaf >/dev/null 2>&1; then
  echo "❌ 'kaf' command not found even after installation."
  exit 1
fi
echo "✅ Kafka CLI 'kaf' installed and available."

# === 2. Verification ===
echo
echo "🧪 Verifying Kafka CLI..."

kaf_version_output="$(kaf --version 2>&1)"
if [[ $? -ne 0 || -z "$kaf_version_output" ]]; then
  echo "❌ Failed to verify kaf (non-zero exit code or empty output)."
  echo "   Output was:"
  echo "   $kaf_version_output"
  exit 1
fi

echo "📌 kaf: $kaf_version_output"
echo "✅ Kafka CLI verification successful."

# === 3. Configure Zsh completion ===
echo
echo "⚙️  Configuring Zsh completion for kaf..."

ZSHRC_PATH="$HOME/.zshrc"
KAF_COMPLETION_LINE='source <(kaf completion zsh)'

if [[ -f "$ZSHRC_PATH" ]]; then
  if grep -Fq "$KAF_COMPLETION_LINE" "$ZSHRC_PATH"; then
    echo "     - Zsh completion line for kaf already present in ~/.zshrc"
  else
    {
      echo ""
      echo "# Added by kafka_cli.zsh on $(date)"
      echo "$KAF_COMPLETION_LINE"
    } >> "$ZSHRC_PATH"
    echo "     - Added kaf Zsh completion line to ~/.zshrc"
  fi
else
  {
    echo "# Created by kafka_cli.zsh on $(date)"
    echo "$KAF_COMPLETION_LINE"
  } >> "$ZSHRC_PATH"
  echo "     - Created ~/.zshrc and added kaf Zsh completion line"
fi

# === 4. Wrap-up ===
echo
echo "💡 Next steps:"
echo "   • To pick up changes now, run: source ~/.zshrc"
echo "   • Show help:             kaf --help"
echo "   • Show configured topics: kaf topics"
echo "   • More info:             see the kaf GitHub repo (birdayz/kaf)"
echo
echo "🎉 Kafka CLI (kaf) installation finished successfully!"



