#!/bin/zsh
# === dexter.zsh ===
# Purpose: Install Dexter (fast Elixir LSP by Remote) via Mise
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🧠 Starting Dexter Elixir LSP installation via Mise..."
echo

# === 1. Verify Mise is available ===
if ! command -v mise >/dev/null 2>&1; then
  echo "❌ Mise is not installed. Please run mise.zsh first."
  exit 1
fi
echo "✅ Mise detected."

# === 2. Install Dexter via Mise (aqua: remoteoss/dexter) ===
echo
echo "📥 Installing Dexter via Mise (aqua:remoteoss/dexter@latest)..."
if ! mise use -g aqua:remoteoss/dexter@latest; then
  echo "❌ Failed to install Dexter via Mise."
  echo "   Check network/aqua registry, or fall back to: brew install dexter-lsp"
  exit 1
fi
echo "✅ Dexter installed and activated globally via Mise."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

dexter_path=$(mise exec -- command -v dexter 2>/dev/null)
if [[ -z "$dexter_path" ]]; then
  echo "❌ dexter not found in Mise PATH."
  exit 1
fi
echo "📌 dexter: $dexter_path"

dexter_version=$(mise exec -- dexter --version 2>/dev/null)
if [[ -n "$dexter_version" ]]; then
  echo "📌 Version: $dexter_version"
fi

# === 4. Wrap-up ===
echo
echo "✅ Dexter installed successfully!"
echo
echo "💡 Usage:"
echo "   • Index a project:        dexter init ."
echo "   • Run as LSP (stdio):     dexter lsp"
echo "   • Lookup a definition:    dexter lookup MyApp.Accounts"
echo "   • Find references:        dexter references MyApp.Accounts fetch_user"
echo
echo "💡 Editor integration:"
echo "   Point any LSP-capable editor at: dexter lsp"
echo "   (No Emacs/Doom config changes made by this script.)"
echo
echo "🎉 Installation finished successfully!"
