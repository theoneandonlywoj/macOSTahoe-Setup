#!/bin/zsh
# === claude_code.zsh ===
# Purpose: Install Claude Code (Anthropic CLI, AI coding assistant) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "🤖 Starting installation of Claude Code (Anthropic, AI coding assistant) on macOS Tahoe..."
echo

# === Configuration ===
claude_bin="claude"
claude_path="$HOME/.local/bin/claude"

echo "🔗 Binary:             $claude_bin"
echo "📂 Default location:   $claude_path"
echo

# === 1. Check if Claude Code is already installed ===
if command -v "$claude_bin" >/dev/null 2>&1 || [[ -x "$claude_path" ]]; then
  if command -v "$claude_bin" >/dev/null 2>&1; then
    current_version=$("$claude_bin" --version 2>/dev/null || echo "unknown")
    echo "✅ Claude Code is already installed: $claude_bin (version: $current_version)"
  else
    current_version=$("$claude_path" --version 2>/dev/null || echo "unknown")
    echo "✅ Claude Code is already installed at $claude_path (version: $current_version)"
    echo "⚙️  Adding $HOME/.local/bin to PATH for this session..."
    export PATH="$HOME/.local/bin:$PATH"
  fi
  echo
  echo "💡 To update, run: claude update"
  echo "   or:              curl -fsSL https://claude.ai/install.sh | bash"
  echo "🎉 Nothing to do!"
  exit 0
fi

# === 2. Install Claude Code ===
echo "📥 Installing Claude Code via official install script..."
curl -fsSL https://claude.ai/install.sh | bash
install_status=$?

claude_found=false
if command -v "$claude_bin" >/dev/null 2>&1 || [[ -x "$claude_path" ]]; then
  claude_found=true
fi

if [[ $install_status -ne 0 ]] && [[ "$claude_found" = false ]]; then
  echo "❌ Claude Code install failed (official install script)."
  echo "⚠️  Try running manually: curl -fsSL https://claude.ai/install.sh | bash"
  exit 1
fi

if command -v "$claude_bin" >/dev/null 2>&1 || [[ -x "$claude_path" ]]; then
  echo "✅ Claude Code installed successfully."
  if ! command -v "$claude_bin" >/dev/null 2>&1; then
    echo "⚙️  Adding $HOME/.local/bin to PATH for this session..."
    export PATH="$HOME/.local/bin:$PATH"
  fi
else
  echo "⚠️  Claude Code not found in PATH or at $claude_path."
  echo "   You may need to restart your terminal."
fi
echo

# === 3. Verify installation ===
echo "🧪 Verifying installation..."
echo

claude_verified=false
if command -v "$claude_bin" >/dev/null 2>&1; then
  installed_version=$("$claude_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Claude Code: $claude_bin (version: $installed_version)"
  claude_verified=true
elif [[ -x "$claude_path" ]]; then
  installed_version=$("$claude_path" --version 2>/dev/null || echo "unknown")
  echo "✅ Claude Code: installed at $claude_path (version: $installed_version)"
  echo "   PATH updated for this session: claude"
  echo "   Future terminals: open a new terminal and run: claude"
  claude_verified=true
fi

if [[ "$claude_verified" = false ]]; then
  echo "⚠️  Claude Code not found in PATH or at $claude_path."
  echo "   Run the following in a new terminal to check: claude --version"
  exit 1
fi

echo
echo "🎉 Claude Code installation complete!"
echo
echo "💡 Next steps:"
echo "   • Authenticate: run claude          (first launch will prompt sign-in)"
echo "   • Or use an API key: claude          (set ANTHROPIC_API_KEY first)"
echo "   • Start it in any project: cd ~/my-project && claude"
echo "   • Config file: ~/.claude/settings.json"
echo "   • Docs: https://docs.anthropic.com/en/docs/claude-code"
