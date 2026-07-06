#!/bin/zsh
# === dive.zsh ===
# Purpose: Install dive — a tool for exploring each layer of a container image
#          and discovering wasted space — via Homebrew on macOS
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting dive installation on macOS..."
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

# === 1. Install dive via Homebrew ===
echo
echo "📥 Installing dive via Homebrew..."
if brew list dive >/dev/null 2>&1; then
  echo "ℹ️  dive is already installed. Upgrading to latest..."
  brew upgrade dive || {
    echo "⚠️  Failed to upgrade dive. Continuing with existing version."
  }
else
  brew install dive
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install dive via Homebrew."
    exit 1
  fi
fi

if ! command -v dive >/dev/null 2>&1; then
  echo "❌ dive command not found even after installation."
  exit 1
fi
echo "✅ dive installed and available."

# === 2. Verification ===
echo
echo "🧪 Verifying dive..."

dive_version=$(dive --version 2>/dev/null | head -n 1)
if [[ -z "$dive_version" ]]; then
  echo "❌ Failed to retrieve dive version. Please check your installation."
  exit 1
fi

echo "📌 dive: $dive_version"
echo "✅ dive setup complete!"

# === 3. Wrap-up ===
echo
echo "💡 Next steps:"
echo "   • Inspect an image's layers:   dive <image>"
echo "       e.g. dive alpine:latest"
echo "   • Tab switches panes; arrows browse layers; Ctrl-c to quit."
echo
echo "   🐳 Podman users (this setup uses podman.zsh):"
echo "      dive defaults to the Docker engine — tell it to use Podman:"
echo "         dive --source podman <image>"
echo "      Or inspect a saved archive (engine-agnostic):"
echo "         podman save <image> -o image.tar && dive --source docker-archive image.tar"
echo
echo "   • Pairs with your podman + docker_compose setup to shrink build layers."
echo
echo "🎉 Installation finished successfully!"
