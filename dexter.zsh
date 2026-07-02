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

# === 4. Ensure Mise shims are on PATH (so GUI-launched editors can spawn dexter) ===
echo
echo "🔗 Ensuring Mise is activated on PATH for shell sessions..."

activate_line='eval "$(mise activate zsh)"'

ensure_in_rc() {
  local rc="$1"
  [[ -f "$rc" ]] || return 1
  if ! grep -qF 'mise activate zsh' "$rc" 2>/dev/null; then
    printf '\n# Added by dexter.zsh — make mise-managed tools (e.g. dexter) discoverable\n%s\n' "$activate_line" >> "$rc"
    echo "✅ Added mise activation to $rc"
  else
    echo "✅ $rc already activates mise."
  fi
}

ensure_in_rc "$HOME/.zshrc"

# Activate mise in the current shell so this session can resolve dexter immediately
if ! eval "$activate_line" 2>/dev/null; then
  echo "⚠️  Could not activate mise in the current shell."
fi

# Sanity check: is dexter resolvable on PATH now (not just via mise exec)?
if command -v dexter >/dev/null 2>&1; then
  echo "📌 dexter on PATH: $(command -v dexter)"
else
  echo "⚠️  dexter still not on PATH in this shell. Open a new terminal, or run: eval \"\$(mise activate zsh)\""
  echo "   (GUI editors may need a full restart to inherit the updated PATH.)"
fi

# === 5. Wrap-up ===
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
