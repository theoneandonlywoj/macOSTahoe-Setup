#!/bin/zsh
# === codex.zsh ===
# Purpose: Install Codex CLI (OpenAI, ChatGPT coding assistant) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "🤖 Starting installation of Codex CLI (OpenAI, ChatGPT coding assistant) on macOS Tahoe..."
echo

# === Configuration ===
codex_bin="codex"
codex_path="$HOME/.local/bin/codex"

echo "🔗 Binary:             $codex_bin"
echo "📂 Default location:   $codex_path"
echo

# === 1. Check if Codex is already installed ===
if command -v "$codex_bin" >/dev/null 2>&1; then
  current_version=$("$codex_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Codex is already installed: $codex_bin (version: $current_version)"
  echo
  echo "💡 To update, run: curl -fsSL https://chatgpt.com/codex/install.sh | sh"
  echo "   or:              brew upgrade --cask codex"
  echo "🎉 Nothing to do!"
  exit 0
fi

# === 2. Ensure Homebrew is installed (needed as fallback) ===
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

# === 3. Install Codex CLI ===
echo "📥 Installing Codex CLI via official install script..."
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
install_status=$?

codex_found=false
if command -v "$codex_bin" >/dev/null 2>&1 || [[ -x "$codex_path" ]]; then
  codex_found=true
fi

if [[ $install_status -ne 0 ]] && [[ "$codex_found" = false ]]; then
  echo "⚠️  Official install script failed. Trying Homebrew cask fallback..."
  brew install --cask codex
  if [[ $? -ne 0 ]]; then
    echo "❌ Codex install failed (official script and Homebrew cask)."
    echo "⚠️  Try running manually: curl -fsSL https://chatgpt.com/codex/install.sh | sh"
    exit 1
  fi
fi

if command -v "$codex_bin" >/dev/null 2>&1 || [[ -x "$codex_path" ]]; then
  echo "✅ Codex CLI installed successfully."
else
  echo "⚠️  Codex CLI not found in PATH or at $codex_path."
  echo "   You may need to restart your terminal."
fi
echo

# === 4. Verify installation ===
echo "🧪 Verifying installation..."
echo

codex_verified=false
if command -v "$codex_bin" >/dev/null 2>&1; then
  installed_version=$("$codex_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Codex CLI: $codex_bin (version: $installed_version)"
  codex_verified=true
elif [[ -x "$codex_path" ]]; then
  installed_version=$("$codex_path" --version 2>/dev/null || echo "unknown")
  echo "✅ Codex CLI: installed at $codex_path (version: $installed_version)"
  echo "   Current terminal: export PATH=\"$HOME/.local/bin:\$PATH\""
  echo "   Future terminals: open a new terminal and run: codex"
  codex_verified=true
fi

if [[ "$codex_verified" = false ]]; then
  echo "⚠️  Codex CLI not found in PATH or at $codex_path."
  echo "   Run the following in a new terminal to check: codex --version"
  exit 1
fi

echo
echo "🎉 Codex CLI installation complete!"
echo
echo "💡 Next steps:"
echo "   • Authenticate: codex login            (sign in with your ChatGPT account)"
echo "   • Or use an API key: codex login --api-key"
echo "   • Start it in any project: cd ~/my-project && codex"
echo "   • Config file: ~/.codex/config.toml"
echo "   • Docs: https://developers.openai.com/codex/cli"
