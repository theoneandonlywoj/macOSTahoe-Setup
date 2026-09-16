#!/bin/zsh
# === orca.zsh ===
# Purpose: Install Orca (agent development environment for parallel coding agents, https://onorca.dev) and detect installed coding-agent CLIs on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj
# Docs: https://onorca.dev/docs

echo "🚀 Starting Orca installation on macOS Tahoe..."
echo

# === Configuration ===
orca_app="/Applications/Orca.app"
orca_bundled_cli="$orca_app/Contents/Resources/bin/orca"
orca_state_dir="$HOME/.orca"

echo "📂 App bundle:         $orca_app"
echo "🔗 Bundled CLI:        $orca_bundled_cli"
echo "📂 State directory:    $orca_state_dir"
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install Orca ===
echo
echo "📥 Installing Orca via Homebrew cask..."
if [[ -d "$orca_app" ]] || command -v orca >/dev/null 2>&1; then
  echo "✅ Orca is already installed. Skipping installation."
  echo "💡 To update, run: brew upgrade --cask orca"
else
  brew install --cask stablyai/orca/orca
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install Orca"
    echo "⚠️  Try running manually: brew install --cask stablyai/orca/orca"
    exit 1
  fi
  echo "✅ Orca installed."
fi

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

app_ok=false
cli_ok=false

if [[ -d "$orca_app" ]]; then
  echo "📌 App: $orca_app"
  app_ok=true
else
  echo "⚠️  Orca.app not found at $orca_app"
fi

orca_path=$(which orca 2>/dev/null)
if [[ -n "$orca_path" ]]; then
  echo "📌 CLI: $orca_path"
  cli_ok=true
elif [[ -x "$orca_bundled_cli" ]]; then
  echo "⚠️  The orca CLI is bundled at $orca_bundled_cli but is not on PATH."
  echo "   💡 Fix: brew reinstall --cask orca   (re-creates the symlink)"
  echo "   💡 Or:  open Orca → Settings → Experimental → CLI"
else
  echo "⚠️  orca CLI not found."
fi

if [[ "$app_ok" = false && "$cli_ok" = false ]]; then
  echo "❌ Orca installation could not be verified."
  exit 1
fi

if [[ "$cli_ok" = true ]]; then
  orca_version=$(orca --version 2>/dev/null | head -1)
  if [[ -n "$orca_version" ]]; then
    echo "📌 Version: $orca_version"
  fi
fi

# === 4. Check first-launch state ===
echo
echo "📥 Checking Orca state..."
if [[ -d "$orca_state_dir" ]]; then
  echo "✅ Orca has been launched before (state in $orca_state_dir)."
else
  echo "ℹ️  Orca has not been launched yet."
  echo "   First launch asks for access to your home directory and offers to import"
  echo "   existing Claude Code, Codex and Ghostty settings. Then add your first repository."
fi

# === 5. Detect coding-agent CLIs Orca integrates with ===
echo
echo "🔗 Detecting installed coding-agent CLIs..."
echo "   (Orca auto-detects agents from PATH via its built-in agent picker — nothing to install)"

# Format: "kind|binary candidates (space-separated)|Display Name"
# Deep integration: usage tracking, account hot-swap, agent hooks
agent_deep=(
  "claude|claude|Claude Code"
  "codex|codex|OpenAI Codex CLI"
  "cursor|cursor-agent|Cursor CLI"
)

# Auto-setup: one-click launch from the agent picker
agent_auto=(
  "opencode|opencode|OpenCode"
  "grok|grok|Grok CLI"
  "pi|pi|Pi"
  "kimi|kimi kimi-cli|Kimi CLI"
  "kilo|kilo kilocode|Kilo Code"
  "hermes|hermes|Hermes Agent"
  "antigravity|antigravity|Antigravity"
  "gemini|gemini|Gemini CLI"
  "amp|amp|Amp"
  "cline|cline|Cline"
  "kiro|kiro|Kiro"
  "goose|goose|Goose"
  "aider|aider|Aider"
  "copilot|copilot gh-copilot|GitHub Copilot CLI"
  "crush|crush|Charm Crush"
  "auggie|auggie|Auggie"
  "droid|droid|Droid (Factory)"
  "qwen|qwen|Qwen Code"
  "continue|cn|Continue"
  "codebuff|codebuff|Codebuff"
  "rovodev|acli rovodev|Rovo Dev"
  "vibe|vibe|Mistral Vibe"
  "prime|prime|Prime Agent"
)

deep_agents=()
auto_agents=()
missing_agents=()

echo
echo "   🔥 Deep integration (usage tracking, account hot-swap, hooks):"
for entry in "${agent_deep[@]}"; do
  rest="${entry#*|}"
  agent_bins="${rest%%|*}"
  agent_label="${rest#*|}"

  found_bin=""
  for bin in ${=agent_bins}; do
    if command -v "$bin" >/dev/null 2>&1; then
      found_bin="$bin"
      break
    fi
  done

  if [[ -n "$found_bin" ]]; then
    echo "      ✅ $agent_label detected ($found_bin)"
    deep_agents+=("$agent_label")
  else
    echo "      ⏭️  Skipped $agent_label (CLI not found)"
    missing_agents+=("$agent_label")
  fi
done

echo
echo "   ⚡ Auto-setup agents:"
for entry in "${agent_auto[@]}"; do
  rest="${entry#*|}"
  agent_bins="${rest%%|*}"
  agent_label="${rest#*|}"

  found_bin=""
  for bin in ${=agent_bins}; do
    if command -v "$bin" >/dev/null 2>&1; then
      found_bin="$bin"
      break
    fi
  done

  if [[ -n "$found_bin" ]]; then
    echo "      ✅ $agent_label detected ($found_bin)"
    auto_agents+=("$agent_label")
  else
    missing_agents+=("$agent_label")
  fi
done
if [[ ${#auto_agents[@]} -eq 0 ]]; then
  echo "      ℹ️  None found."
fi

# === 6. Summary ===
echo
echo "═══════════════════════════════════════════════════"
echo "✨ Orca setup complete!"
echo "═══════════════════════════════════════════════════"
echo
echo "🔥 Deep-integration agents detected:"
if [[ ${#deep_agents[@]} -gt 0 ]]; then
  for agent in "${deep_agents[@]}"; do
    echo "      • $agent"
  done
else
  echo "      (none)"
fi
echo
echo "⚡ Auto-setup agents detected:"
if [[ ${#auto_agents[@]} -gt 0 ]]; then
  for agent in "${auto_agents[@]}"; do
    echo "      • $agent"
  done
else
  echo "      (none)"
fi
echo
echo "⏭️  Not installed (skipped):"
if [[ ${#missing_agents[@]} -gt 0 ]]; then
  for agent in "${missing_agents[@]}"; do
    echo "      • $agent"
  done
else
  echo "      (none)"
fi

# === 7. Wrap-up ===
echo
echo "✅ Orca installed successfully!"
echo
echo "💡 Usage:"
echo "   • Launch the app:                     Spotlight (⌘ Space → 'Orca') or: orca open"
echo "   • Check runtime connectivity:         orca status"
echo "   • Register a repository:              orca repo add ~/project"
echo "   • Create an isolated worktree:        orca worktree create"
echo "   • List active worktrees:              orca worktree ps"
echo "   • Headless server (Tailscale):        orca serve --pairing-address <tailscale-ip>"
echo "   • Pair the mobile app:                orca serve --pairing-address <tailscale-ip> --mobile-pairing"
echo "   • Agent permissions (Yolo/Manual):    Settings → Agents → Agent Permissions"
echo "   • Settings / Quick Open:              ⌘,  /  ⌘J"
echo "   • Update:                             brew upgrade --cask orca"
echo "   • Rerun after adding a new agent CLI: ./orca.zsh"
echo "   • Add Orca to the Dock:               ./dock_cleanup.zsh"
echo "   • Docs:                               https://onorca.dev/docs"
echo "   • CLI reference:                      https://onorca.dev/docs/cli/reference"
echo
echo "🎉 Installation finished successfully!"
