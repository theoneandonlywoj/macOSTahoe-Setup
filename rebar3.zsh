#!/bin/zsh
# === rebar3.zsh ===
# Purpose: Install Rebar3 (Erlang build tool) on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "📦 Starting Rebar3 installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install rebar3 ===
echo
echo "📥 Installing rebar3 via Homebrew..."
if command -v rebar3 >/dev/null 2>&1; then
  echo "ℹ️  rebar3 is already installed. Upgrading to latest..."
  brew upgrade rebar3 2>/dev/null || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install rebar3
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install rebar3"
    exit 1
  fi
fi
echo "✅ rebar3 installed."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

rebar3_path=$(which rebar3 2>/dev/null)
if [[ -z "$rebar3_path" ]]; then
  echo "❌ rebar3 not found in PATH."
  exit 1
fi
echo "📌 rebar3: $rebar3_path"

rebar3_version=$(rebar3 --version 2>/dev/null | head -1)
if [[ -n "$rebar3_version" ]]; then
  echo "📌 Version: $rebar3_version"
fi

# === 4. Wrap-up ===
echo
echo "✅ rebar3 installed successfully!"
echo
echo "💡 Usage:"
echo "   • Create new Erlang/Nerves dep project:  rebar3 new app my_app"
echo "   • Compile:                               rebar3 compile"
echo "   • Run tests:                             rebar3 ct"
echo "   • Build release:                         rebar3 release"
echo "   • Useful for Erlang-only deps in Nerves targets."
echo
echo "🎉 Installation finished successfully!"
